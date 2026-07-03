//
//  AppDelegate.swift
//  MineRadio
//
//  Created by MineRadio Team on 2026/7/3.
//

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 配置音频会话，支持后台播放
        setupAudioSession()
        
        // 创建主窗口
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        
        // 设置根视图控制器
        let mainVC = MainViewController()
        window?.rootViewController = mainVC
        window?.makeKeyAndVisible()
        
        return true
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
    
    // MARK: - 应用生命周期
    func applicationDidEnterBackground(_ application: UIApplication) {
        // 应用进入后台时的处理
        NotificationCenter.default.post(name: .appDidEnterBackground, object: nil)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // 应用进入前台时的处理
        NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 应用激活时的处理
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // 应用即将失活时的处理
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // 应用终止时的处理
        NotificationCenter.default.post(name: .appWillTerminate, object: nil)
    }
}

// MARK: - 自定义通知名称
extension Notification.Name {
    static let appDidEnterBackground = Notification.Name("AppDidEnterBackground")
    static let appWillEnterForeground = Notification.Name("AppWillEnterForeground")
    static let appWillTerminate = Notification.Name("AppWillTerminate")
}
