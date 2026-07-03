//
//  HandGestureManager.swift
//  MineRadio
//
//  Created by MineRadio Team on 2026/7/3.
//

import Foundation
import UIKit
import AVFoundation
import Vision

// MARK: - 手势类型枚举
enum HandGesture: String {
    case unknown = "unknown"
    case open = "open"           // 张开手掌
    case closed = "closed"       // 握拳
    case point = "point"         // 食指指向
    case victory = "victory"     // 剪刀手
    case thumbUp = "thumbUp"     // 点赞
    case thumbDown = "thumbDown" // 差评
}

// MARK: - 代理协议
protocol HandGestureManagerDelegate: AnyObject {
    func handGestureManager(_ manager: HandGestureManager, didDetectGesture gesture: HandGesture, landmarks: [CGPoint])
}

// MARK: - 手势识别管理器
@available(iOS 14.0, *)
class HandGestureManager: NSObject {
    
    // MARK: - 属性
    weak var delegate: HandGestureManagerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var handPoseRequest: VNDetectHumanHandPoseRequest?
    private var handLandmarksRequest: VNDetectFaceLandmarksRequest?
    
    private var isRunning = false
    private let processingQueue = DispatchQueue(label: "com.mineradio.handgesture.queue")
    
    // 手势冷却时间，避免频繁触发
    private var lastGestureTime: TimeInterval = 0
    private let gestureCooldown: TimeInterval = 0.5
    
    // MARK: - 初始化
    override init() {
        super.init()
        setupVisionRequests()
        setupNotificationObservers()
    }
    
    // MARK: - 设置Vision请求
    private func setupVisionRequests() {
        // 手部姿态识别请求
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest?.maximumHandCount = 1
    }
    
    // MARK: - 设置通知观察者
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStartGesture),
            name: .startHandGesture,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStopGesture),
            name: .stopHandGesture,
            object: nil
        )
    }
    
    // MARK: - 启动手势识别
    func start() {
        guard !isRunning else { return }
        
        // 请求相机权限
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupCaptureSession()
                    self?.captureSession?.startRunning()
                    self?.isRunning = true
                } else {
                    print("相机权限被拒绝")
                }
            }
        }
    }
    
    // MARK: - 停止手势识别
    func stop() {
        guard isRunning else { return }
        
        captureSession?.stopRunning()
        isRunning = false
    }
    
    // MARK: - 设置捕获会话
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: captureDevice),
              captureSession?.canAddInput(input) == true else {
            print("无法设置相机输入")
            return
        }
        
        captureSession?.addInput(input)
        
        // 设置视频输出
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput?.alwaysDiscardsLateVideoFrames = true
        videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true {
            captureSession?.addOutput(videoOutput)
        }
        
        // 设置连接方向
        if let connection = videoOutput?.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
    }
    
    // MARK: - 处理手势启动通知
    @objc private func handleStartGesture() {
        start()
    }
    
    // MARK: - 处理手势停止通知
    @objc private func handleStopGesture() {
        stop()
    }
    
    // MARK: - 处理手部姿态识别结果
    private func processHandPoseObservations(_ observations: [VNHumanHandPoseObservation]) {
        guard !observations.isEmpty else { return }
        
        // 只处理第一只手
        guard let handObservation = observations.first else { return }
        
        do {
            // 获取所有关键点
            let landmarks = try handObservation.recognizedPoints(.all)
            
            // 转换关键点坐标
            var landmarkPoints: [CGPoint] = []
            for (_, point) in landmarks {
                if point.confidence > 0.3 {
                    let cgPoint = CGPoint(x: point.x, y: point.y)
                    landmarkPoints.append(cgPoint)
                }
            }
            
            // 识别手势
            let gesture = recognizeGesture(from: landmarks)
            
            // 检查冷却时间
            let currentTime = Date().timeIntervalSince1970
            if currentTime - lastGestureTime > gestureCooldown {
                lastGestureTime = currentTime
                
                // 通知代理
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.handGestureManager(self, didDetectGesture: gesture, landmarks: landmarkPoints)
                }
            }
            
        } catch {
            print("手部姿态处理失败: \(error)")
        }
    }
    
    // MARK: - 手势识别算法
    private func recognizeGesture(from landmarks: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) -> HandGesture {
        // 获取手指关键点
        guard let thumbTip = landmarks[.thumbTip],
              let thumbIP = landmarks[.thumbIP],
              let thumbMP = landmarks[.thumbMP],
              let thumbCMC = landmarks[.thumbCMC],
              let indexTip = landmarks[.indexTip],
              let indexDIP = landmarks[.indexDIP],
              let indexPIP = landmarks[.indexPIP],
              let indexMCP = landmarks[.indexMCP],
              let middleTip = landmarks[.middleTip],
              let middleDIP = landmarks[.middleDIP],
              let middlePIP = landmarks[.middlePIP],
              let middleMCP = landmarks[.middleMCP],
              let ringTip = landmarks[.ringTip],
              let ringDIP = landmarks[.ringDIP],
              let ringPIP = landmarks[.ringPIP],
              let ringMCP = landmarks[.ringMCP],
              let littleTip = landmarks[.littleTip],
              let littleDIP = landmarks[.littleDIP],
              let littlePIP = landmarks[.littlePIP],
              let littleMCP = landmarks[.littleMCP],
              let wrist = landmarks[.wrist] else {
            return .unknown
        }
        
        // 计算手指是否弯曲
        let indexFolded = isFingerFolded(tip: indexTip, pip: indexPIP, mcp: indexMCP, wrist: wrist)
        let middleFolded = isFingerFolded(tip: middleTip, pip: middlePIP, mcp: middleMCP, wrist: wrist)
        let ringFolded = isFingerFolded(tip: ringTip, pip: ringPIP, mcp: ringMCP, wrist: wrist)
        let littleFolded = isFingerFolded(tip: littleTip, pip: littlePIP, mcp: littleMCP, wrist: wrist)
        let thumbFolded = isThumbFolded(tip: thumbTip, ip: thumbIP, mp: thumbMP, cmc: thumbCMC)
        
        // 判断手势
        if !indexFolded && !middleFolded && ringFolded && littleFolded {
            return .victory
        } else if !indexFolded && middleFolded && ringFolded && littleFolded {
            return .point
        } else if indexFolded && middleFolded && ringFolded && littleFolded && !thumbFolded {
            // 判断拇指方向
            if thumbTip.y < thumbMP.y {
                return .thumbUp
            } else {
                return .thumbDown
            }
        } else if indexFolded && middleFolded && ringFolded && littleFolded && thumbFolded {
            return .closed
        } else if !indexFolded && !middleFolded && !ringFolded && !littleFolded {
            return .open
        }
        
        return .unknown
    }
    
    // MARK: - 判断手指是否弯曲
    private func isFingerFolded(tip: VNRecognizedPoint, pip: VNRecognizedPoint, mcp: VNRecognizedPoint, wrist: VNRecognizedPoint) -> Bool {
        // 计算指尖到手腕的距离
        let tipToWrist = distanceBetween(tip.location, wrist.location)
        // 计算MCP到手腕的距离
        let mcpToWrist = distanceBetween(mcp.location, wrist.location)
        
        // 如果指尖到手腕的距离小于MCP到手腕距离的1.2倍，认为手指弯曲
        return tipToWrist < mcpToWrist * 1.2
    }
    
    // MARK: - 判断拇指是否弯曲
    private func isThumbFolded(tip: VNRecognizedPoint, ip: VNRecognizedPoint, mp: VNRecognizedPoint, cmc: VNRecognizedPoint) -> Bool {
        let tipToCMC = distanceBetween(tip.location, cmc.location)
        let mpToCMC = distanceBetween(mp.location, cmc.location)
        
        return tipToCMC < mpToCMC * 1.3
    }
    
    // MARK: - 计算两点距离
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - 内存管理
    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
@available(iOS 14.0, *)
extension HandGestureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            // 执行手部姿态识别请求
            if let handPoseRequest = handPoseRequest {
                try requestHandler.perform([handPoseRequest])
                
                if let observations = handPoseRequest.results {
                    processHandPoseObservations(observations)
                }
            }
            
        } catch {
            print("Vision请求执行失败: \(error)")
        }
    }
}
