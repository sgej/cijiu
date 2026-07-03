//
//  MainViewController.swift
//  MineRadio
//
//  Created by MineRadio Team on 2026/7/3.
//

import UIKit
import WebKit

class MainViewController: UIViewController {
    
    // MARK: - 属性
    private var webView: WKWebView!
    private var bridgeManager: JSBridgeManager!
    private var musicPlayer: MusicPlayerService!
    private var handGestureManager: HandGestureManager?
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupServices()
        loadWebContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 隐藏导航栏
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.backgroundColor = .black
        
        // 配置WebView
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.preferences.javaScriptEnabled = true
        webConfiguration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // 注入用户脚本
        let userContentController = WKUserContentController()
        webConfiguration.userContentController = userContentController
        
        // 创建WebView
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = .black
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        view.addSubview(webView)
    }
    
    // MARK: - 服务初始化
    private func setupServices() {
        // 初始化音乐播放器
        musicPlayer = MusicPlayerService()
        
        // 初始化JS桥接管理器
        bridgeManager = JSBridgeManager(webView: webView, musicPlayer: musicPlayer)
        bridgeManager.delegate = self
        
        // 初始化手势识别（可选，根据设备能力）
        if #available(iOS 14.0, *) {
            handGestureManager = HandGestureManager()
            handGestureManager?.delegate = self
        }
    }
    
    // MARK: - 加载Web内容
    private func loadWebContent() {
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "WebContent") else {
            print("找不到HTML文件")
            return
        }
        
        let htmlURL = URL(fileURLWithPath: htmlPath)
        let baseURL = htmlURL.deletingLastPathComponent()
        
        do {
            let htmlString = try String(contentsOf: htmlURL, encoding: .utf8)
            webView.loadHTMLString(htmlString, baseURL: baseURL)
        } catch {
            print("加载HTML失败: \(error)")
        }
    }
    
    // MARK: - 内存管理
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // 清理缓存
        URLCache.shared.removeAllCachedResponses()
    }
    
    deinit {
        // 清理WebView
        webView.stopLoading()
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
    }
}

// MARK: - WKNavigationDelegate
extension MainViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Web页面加载完成")
        // 通知JS原生环境已准备就绪
        bridgeManager.notifyNativeReady()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web页面加载失败: \(error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Web页面加载失败(Provisional): \(error)")
    }
}

// MARK: - WKUIDelegate
extension MainViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }
}

// MARK: - JSBridgeManagerDelegate
extension MainViewController: JSBridgeManagerDelegate {
    
    func bridgeManager(_ manager: JSBridgeManager, didRequestOpenURL url: URL) {
        UIApplication.shared.open(url)
    }
    
    func bridgeManagerDidRequestShowFilePicker(_ manager: JSBridgeManager) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }
    
    func bridgeManagerDidRequestShowImagePicker(_ manager: JSBridgeManager) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension MainViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // 处理选择的音频文件
        bridgeManager.handleLocalFilesSelected(urls: urls)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            bridgeManager.handleBackgroundImageSelected(image: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - HandGestureManagerDelegate
extension MainViewController: HandGestureManagerDelegate {
    
    func handGestureManager(_ manager: HandGestureManager, didDetectGesture gesture: HandGesture, landmarks: [CGPoint]) {
        // 将手势识别结果传递给JS
        bridgeManager.sendHandGestureResult(gesture: gesture, landmarks: landmarks)
    }
}
