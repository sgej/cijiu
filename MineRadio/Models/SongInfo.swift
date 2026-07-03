//
//  SongInfo.swift
//  MineRadio
//
//  Created by MineRadio Team on 2026/7/3.
//

import Foundation

// MARK: - 歌曲信息模型
struct SongInfo {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: Double
    let coverUrl: String?
    let url: URL
}

// MARK: - 播放状态枚举
enum MusicPlayerState {
    case idle
    case playing
    case paused
    case stopped
    case error
}

// MARK: - 播放模式枚举
enum PlayMode {
    case sequence     // 顺序播放
    case loop         // 单曲循环
    case shuffle      // 随机播放
}
