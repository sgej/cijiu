//
//  JSBridgeManager.swift
//  MineRadio
//
//  Created by MineRadio Team on 2026/7/3.
//

import UIKit
import WebKit

// MARK: - 代理协议
protocol JSBridgeManagerDelegate: AnyObject {
    func bridgeManager(_ manager: JSBridgeManager, didRequestOpenURL url: URL)
    func bridgeManagerDidRequestShowFilePicker(_ manager: JSBridgeManager)
    func bridgeManagerDidRequestShowImagePicker(_ manager: JSBridgeManager)
}

// MARK: - JS桥接管理器
class JSBridgeManager: NSObject {
    
    // MARK: - 属性
    weak var delegate: JSBridgeManagerDelegate?
    private weak var webView: WKWebView?
    private weak var musicPlayer: MusicPlayerService?
    
    // 桥接消息处理器名称
    private let messageHandlerName = "nativeBridge"
    
    // MARK: - 初始化
    init(webView: WKWebView, musicPlayer: MusicPlayerService) {
        self.webView = webView
        self.musicPlayer = musicPlayer
        super.init()
        setupMessageHandler()
        setupMusicPlayerObserver()
    }
    
    // MARK: - 设置消息处理器
    private func setupMessageHandler() {
        webView?.configuration.userContentController.add(self, name: messageHandlerName)
    }
    
    // MARK: - 音乐播放器观察者
    private func setupMusicPlayerObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayStateChange),
            name: .musicPlayerStateChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayProgressChange),
            name: .musicPlayerProgressChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCurrentSongChanged),
            name: .musicPlayerCurrentSongChanged,
            object: nil
        )
    }
    
    // MARK: - 通知JS原生环境就绪
    func notifyNativeReady() {
        let js = """
        if (typeof window.__onNativeReady === 'function') {
            window.__onNativeReady({
                platform: 'ios',
                version: '1.1.4',
                features: {
                    localMusic: true,
                    handGesture: \(handGestureAvailable()),
                    backgroundPlay: true,
                    desktopLyrics: false,
                    liveWallpaper: false
                }
            });
        }
        """
        evaluateJavaScript(js)
    }
    
    // MARK: - 检查手势识别是否可用
    private func handGestureAvailable() -> Bool {
        if #available(iOS 14.0, *) {
            return true
        }
        return false
    }
    
    // MARK: - 执行JS代码
    private func evaluateJavaScript(_ js: String) {
        webView?.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("JS执行失败: \(error)")
            }
        }
    }
    
    // MARK: - 发送事件到JS
    private func sendEventToJS(_ event: String, data: [String: Any]? = nil) {
        var jsString = "if (typeof window.__nativeEvent === 'function') { window.__nativeEvent('\(event)'"
        
        if let data = data,
           let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            jsString += ", \(jsonString)"
        }
        
        jsString += "); }"
        evaluateJavaScript(jsString)
    }
    
    // MARK: - 处理本地文件选择
    func handleLocalFilesSelected(urls: [URL]) {
        var fileInfos: [[String: Any]] = []
        
        for url in urls {
            let fileName = url.lastPathComponent
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            
            // 复制文件到应用沙盒
            if let cachedURL = cacheLocalFile(url: url) {
                fileInfos.append([
                    "name": fileName,
                    "size": fileSize,
                    "path": cachedURL.path,
                    "url": cachedURL.absoluteString
                ])
            }
        }
        
        // 通知JS
        let data: [String: Any] = ["files": fileInfos]
        sendEventToJS("localFilesSelected", data: data)
    }
    
    // MARK: - 缓存本地文件
    private func cacheLocalFile(url: URL) -> URL? {
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let musicDir = cacheDir.appendingPathComponent("LocalMusic", isDirectory: true)
        
        // 创建目录
        if !fileManager.fileExists(atPath: musicDir.path) {
            try? fileManager.createDirectory(at: musicDir, withIntermediateDirectories: true)
        }
        
        let destURL = musicDir.appendingPathComponent(url.lastPathComponent)
        
        // 如果文件已存在，直接返回
        if fileManager.fileExists(atPath: destURL.path) {
            return destURL
        }
        
        // 复制文件
        do {
            try fileManager.copyItem(at: url, to: destURL)
            return destURL
        } catch {
            print("文件缓存失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 处理背景图片选择
    func handleBackgroundImageSelected(image: UIImage) {
        // 保存图片到缓存
        if let imageData = image.jpegData(compressionQuality: 0.8),
           let imageURL = saveBackgroundImage(data: imageData) {
            let data: [String: Any] = [
                "url": imageURL.absoluteString,
                "width": image.size.width,
                "height": image.size.height
            ]
            sendEventToJS("backgroundImageSelected", data: data)
        }
    }
    
    // MARK: - 保存背景图片
    private func saveBackgroundImage(data: Data) -> URL? {
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let bgDir = cacheDir.appendingPathComponent("Backgrounds", isDirectory: true)
        
        if !fileManager.fileExists(atPath: bgDir.path) {
            try? fileManager.createDirectory(at: bgDir, withIntermediateDirectories: true)
        }
        
        let fileName = "bg_\(Date().timeIntervalSince1970).jpg"
        let fileURL = bgDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("背景图片保存失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 发送手势识别结果
    func sendHandGestureResult(gesture: HandGesture, landmarks: [CGPoint]) {
        let landmarkArray = landmarks.map { ["x": $0.x, "y": $0.y] }
        let data: [String: Any] = [
            "gesture": gesture.rawValue,
            "landmarks": landmarkArray
        ]
        sendEventToJS("handGestureDetected", data: data)
    }
    
    // MARK: - 音乐播放器通知处理
    @objc private func handlePlayStateChange(_ notification: Notification) {
        guard let state = notification.userInfo?["state"] as? MusicPlayerState else { return }
        
        let data: [String: Any] = [
            "state": state == .playing ? "playing" : "paused"
        ]
        sendEventToJS("playStateChanged", data: data)
    }
    
    @objc private func handlePlayProgressChange(_ notification: Notification) {
        guard let progress = notification.userInfo?["progress"] as? Double,
              let duration = notification.userInfo?["duration"] as? Double else { return }
        
        let data: [String: Any] = [
            "currentTime": progress,
            "duration": duration,
            "progress": duration > 0 ? progress / duration : 0
        ]
        sendEventToJS("playProgressChanged", data: data)
    }
    
    @objc private func handleCurrentSongChanged(_ notification: Notification) {
        guard let song = notification.userInfo?["song"] as? SongInfo else { return }
        
        let data: [String: Any] = [
            "id": song.id,
            "title": song.title,
            "artist": song.artist,
            "album": song.album ?? "",
            "duration": song.duration,
            "coverUrl": song.coverUrl ?? ""
        ]
        sendEventToJS("currentSongChanged", data: data)
    }
    
    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: messageHandlerName)
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - WKScriptMessageHandler
extension JSBridgeManager: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == messageHandlerName,
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }
        
        let data = body["data"] as? [String: Any]
        handleJSAction(action, data: data)
    }
    
    // MARK: - 处理JS调用的动作
    private func handleJSAction(_ action: String, data: [String: Any]?) {
        switch action {
        case "playMusic":
            handlePlayMusic(data: data)
        case "pauseMusic":
            handlePauseMusic()
        case "resumeMusic":
            handleResumeMusic()
        case "seekTo":
            handleSeekTo(data: data)
        case "setVolume":
            handleSetVolume(data: data)
        case "importLocalMusic":
            handleImportLocalMusic()
        case "pickBackgroundImage":
            handlePickBackgroundImage()
        case "openURL":
            handleOpenURL(data: data)
        case "startHandGesture":
            handleStartHandGesture()
        case "stopHandGesture":
            handleStopHandGesture()
        case "getDeviceInfo":
            handleGetDeviceInfo()
        default:
            print("未知的JS动作: \(action)")
        }
    }
    
    // MARK: - 音乐播放控制
    private func handlePlayMusic(data: [String: Any]?) {
        guard let urlString = data?["url"] as? String,
              let url = URL(string: urlString) else {
            return
        }
        
        let song = SongInfo(
            id: data?["id"] as? String ?? "",
            title: data?["title"] as? String ?? "未知歌曲",
            artist: data?["artist"] as? String ?? "未知艺术家",
            album: data?["album"] as? String,
            duration: data?["duration"] as? Double ?? 0,
            coverUrl: data?["coverUrl"] as? String,
            url: url
        )
        
        musicPlayer?.play(song: song)
    }
    
    private func handlePauseMusic() {
        musicPlayer?.pause()
    }
    
    private func handleResumeMusic() {
        musicPlayer?.resume()
    }
    
    private func handleSeekTo(data: [String: Any]?) {
        guard let time = data?["time"] as? Double else { return }
        musicPlayer?.seek(to: time)
    }
    
    private func handleSetVolume(data: [String: Any]?) {
        guard let volume = data?["volume"] as? Float else { return }
        musicPlayer?.setVolume(volume)
    }
    
    // MARK: - 导入本地音乐
    private func handleImportLocalMusic() {
        delegate?.bridgeManagerDidRequestShowFilePicker(self)
    }
    
    // MARK: - 选择背景图片
    private func handlePickBackgroundImage() {
        delegate?.bridgeManagerDidRequestShowImagePicker(self)
    }
    
    // MARK: - 打开URL
    private func handleOpenURL(data: [String: Any]?) {
        guard let urlString = data?["url"] as? String,
              let url = URL(string: urlString) else {
            return
        }
        delegate?.bridgeManager(self, didRequestOpenURL: url)
    }
    
    // MARK: - 手势识别控制
    private func handleStartHandGesture() {
        NotificationCenter.default.post(name: .startHandGesture, object: nil)
    }
    
    private func handleStopHandGesture() {
        NotificationCenter.default.post(name: .stopHandGesture, object: nil)
    }
    
    // MARK: - 获取设备信息
    private func handleGetDeviceInfo() {
        let device = UIDevice.current
        let info: [String: Any] = [
            "platform": "ios",
            "systemVersion": device.systemVersion,
            "model": device.model,
            "screenWidth": UIScreen.main.bounds.width,
            "screenHeight": UIScreen.main.bounds.height,
            "devicePixelRatio": UIScreen.main.scale
        ]
        sendEventToJS("deviceInfo", data: info)
    }
}

// MARK: - 手势相关通知
extension Notification.Name {
    static let startHandGesture = Notification.Name("StartHandGesture")
    static let stopHandGesture = Notification.Name("StopHandGesture")
}
