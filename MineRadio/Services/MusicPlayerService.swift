//
//  MusicPlayerService.swift
//  MineRadio
//
//  Created by MineRadio Team on 2026/7/3.
//

import Foundation
import AVFoundation
import MediaPlayer

// MARK: - 音乐播放器服务
class MusicPlayerService: NSObject {
    
    // MARK: - 属性
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    private(set) var currentSong: SongInfo?
    private(set) var state: MusicPlayerState = .idle
    private(set) var playMode: PlayMode = .sequence
    
    private var playlist: [SongInfo] = []
    private var currentIndex: Int = 0
    
    // MARK: - 初始化
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    // MARK: - 音频会话配置
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            print("音频会话配置失败: \(error)")
        }
    }
    
    // MARK: - 远程控制中心配置
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 播放/暂停
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if self?.state == .playing {
                self?.pause()
            } else {
                self?.resume()
            }
            return .success
        }
        
        // 上一首/下一首
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        // 进度调整
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: positionEvent.positionTime)
            }
            return .success
        }
    }
    
    // MARK: - 更新锁屏信息
    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyPlaybackDuration: song.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: state == .playing ? 1.0 : 0.0
        ]
        
        // 如果有封面图
        if let coverUrl = song.coverUrl, let url = URL(string: coverUrl) {
            // 异步加载封面图
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - 播放控制
    func play(song: SongInfo) {
        currentSong = song
        setupPlayerItem(with: song.url)
        player?.play()
        state = .playing
        
        // 通知状态变化
        notifyStateChanged()
        notifyCurrentSongChanged()
        updateNowPlayingInfo()
    }
    
    func playPlaylist(_ songs: [SongInfo], startIndex: Int = 0) {
        playlist = songs
        currentIndex = startIndex
        
        if currentIndex < playlist.count {
            play(song: playlist[currentIndex])
        }
    }
    
    func pause() {
        player?.pause()
        state = .paused
        notifyStateChanged()
        updateNowPlayingInfo()
    }
    
    func resume() {
        player?.play()
        state = .playing
        notifyStateChanged()
        updateNowPlayingInfo()
    }
    
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        state = .stopped
        notifyStateChanged()
    }
    
    func playNext() {
        guard !playlist.isEmpty else { return }
        
        switch playMode {
        case .shuffle:
            currentIndex = Int.random(in: 0..<playlist.count)
        case .loop:
            // 单曲循环，重新播放当前歌曲
            seek(to: 0)
            return
        case .sequence:
            currentIndex = (currentIndex + 1) % playlist.count
        }
        
        if currentIndex < playlist.count {
            play(song: playlist[currentIndex])
        }
    }
    
    func playPrevious() {
        guard !playlist.isEmpty else { return }
        
        // 如果播放时间超过3秒，重新播放当前歌曲
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        
        switch playMode {
        case .shuffle:
            currentIndex = Int.random(in: 0..<playlist.count)
        case .loop:
            seek(to: 0)
            return
        case .sequence:
            currentIndex = (currentIndex - 1 + playlist.count) % playlist.count
        }
        
        if currentIndex < playlist.count {
            play(song: playlist[currentIndex])
        }
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = max(0, min(1, volume))
    }
    
    func setPlayMode(_ mode: PlayMode) {
        playMode = mode
    }
    
    // MARK: - 播放器设置
    private func setupPlayerItem(with url: URL) {
        // 移除旧的观察者
        removePlayerObservers()
        
        // 创建新的PlayerItem
        playerItem = AVPlayerItem(url: url)
        
        // 如果player不存在则创建
        if player == nil {
            player = AVPlayer()
            player?.automaticallyWaitsToMinimizeStalling = false
        }
        
        // 替换当前播放项
        player?.replaceCurrentItem(with: playerItem)
        
        // 添加观察者
        addPlayerObservers()
    }
    
    // MARK: - 观察者管理
    private func addPlayerObservers() {
        guard let playerItem = playerItem else { return }
        
        // 播放完成通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // 播放失败通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )
        
        // 进度观察者
        let interval = CMTime(seconds: 0.5, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleProgressUpdate(time: time)
        }
    }
    
    private func removePlayerObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    // MARK: - 播放事件处理
    @objc private func playerItemDidFinishPlaying() {
        // 播放完成，根据播放模式处理
        switch playMode {
        case .loop:
            seek(to: 0)
            player?.play()
        case .sequence, .shuffle:
            playNext()
        }
    }
    
    @objc private func playerItemFailedToPlay() {
        state = .error
        notifyStateChanged()
        print("播放失败")
    }
    
    private func handleProgressUpdate(time: CMTime) {
        let currentTime = time.seconds
        let duration = playerItem?.duration.seconds ?? 0
        
        // 通知进度变化
        NotificationCenter.default.post(
            name: .musicPlayerProgressChanged,
            object: nil,
            userInfo: [
                "progress": currentTime,
                "duration": duration
            ]
        )
    }
    
    // MARK: - 通知发送
    private func notifyStateChanged() {
        NotificationCenter.default.post(
            name: .musicPlayerStateChanged,
            object: nil,
            userInfo: ["state": state]
        )
    }
    
    private func notifyCurrentSongChanged() {
        guard let song = currentSong else { return }
        NotificationCenter.default.post(
            name: .musicPlayerCurrentSongChanged,
            object: nil,
            userInfo: ["song": song]
        )
    }
    
    // MARK: - 计算属性
    var currentTime: Double {
        return player?.currentTime().seconds ?? 0
    }
    
    var duration: Double {
        return playerItem?.duration.seconds ?? 0
    }
    
    var volume: Float {
        return player?.volume ?? 1.0
    }
    
    // MARK: - 内存管理
    deinit {
        removePlayerObservers()
        player?.pause()
        player = nil
    }
}

// MARK: - 音乐播放器通知
extension Notification.Name {
    static let musicPlayerStateChanged = Notification.Name("MusicPlayerStateChanged")
    static let musicPlayerProgressChanged = Notification.Name("MusicPlayerProgressChanged")
    static let musicPlayerCurrentSongChanged = Notification.Name("MusicPlayerCurrentSongChanged")
}
