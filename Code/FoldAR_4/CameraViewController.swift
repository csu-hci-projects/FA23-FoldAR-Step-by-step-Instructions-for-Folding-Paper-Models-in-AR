//
//  CameraViewController.swift
//  FoldAR_5
//
//  Created by Tom Cavey on 11/02/23.

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController
{

    private var cameraView: CameraView { view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var evidenceBuffer = [HandGestureProcessor.PointsPair]()
    private var lastObservationTimestamp = Date()
    private var gestureProcessor = HandGestureProcessor()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // This sample app detects one hand only.
        handPoseRequest.maximumHandCount = 2
        
        // Add state change handler to hand gesture processor.
        gestureProcessor.didChangeStateClosure =
        {
            [weak self] state in
            self?.handleGestureStateChange(state: state)
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        do
        {
            if cameraFeedSession == nil
            {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        }
        catch
        {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func setupAVSession() throws
    {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        else
        {
            throw AppError.captureSessionSetup(reason: "Could not find a back facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice)
        else
        {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput)
        else
        {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput)
        {
            session.addOutput(dataOutput)
            
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        }
        else
        {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    func processPoints(thumbTip: CGPoint?, thumbBase: CGPoint?, thumbIP_p: CGPoint?, thumbMP_p: CGPoint?)
    {
        // Check that we havea all thumb points
        guard let thumbPoint = thumbTip, let basePoint = thumbBase, let tIPpoint = thumbIP_p, let tMPpoint = thumbMP_p
        else
        {
            // If there were no observations for more than 2 seconds reset gesture processor.
            if Date().timeIntervalSince(lastObservationTimestamp) > 2
            {
                gestureProcessor.reset()
            }
            cameraView.showPoints([], color: .clear)
            return
        }
        
        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView.previewLayer
        let thumbPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: thumbPoint)
        let basePointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: basePoint)
        let tIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: tIPpoint)
        let tMPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: tMPpoint)
        
        // Process new points
        gestureProcessor.processPointsPair((thumbPointConverted, basePointConverted, tIPPointConverted, tMPPointConverted ))
    }
    
    private func handleGestureStateChange(state: HandGestureProcessor.State)
    {
        let pointsPair = gestureProcessor.lastProcessedPointsPair
        var tipsColor: UIColor
        switch state
        {
            case .thumbDown:
                evidenceBuffer.append(pointsPair)
                tipsColor = .red
                
            case .thumbUp:
                evidenceBuffer.append(pointsPair)
                tipsColor = .green
                
            case .unknown:
                evidenceBuffer.removeAll()
                tipsColor = .black
        }
        cameraView.showPoints([pointsPair.thumbTip, pointsPair.thumbBase, pointsPair.thumbIP, pointsPair.thumbMP], color: tipsColor)
    }
    
    
    @IBAction func handleGesture(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        evidenceBuffer.removeAll()
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var thumbTip: CGPoint?
        var thumbBase: CGPoint?
        var thumbIP: CGPoint?
        var thumbMP: CGPoint?
        
        defer
        {
            DispatchQueue.main.sync
            {
                self.processPoints(thumbTip: thumbTip, thumbBase: thumbBase, thumbIP_p: thumbIP, thumbMP_p: thumbMP)
            }
        }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first
            else
            {
                return
            }
            
            // Get points for thumb
            let thumbPoints = try observation.recognizedPoints(.thumb)
            let indexPoints = try observation.recognizedPoints(.indexFinger)
            
            guard let thumbTipPoint = thumbPoints[.thumbTip], let thumbIP_p = thumbPoints[.thumbIP], let thumbMP_p = thumbPoints[.thumbMP], let thumbBasePoint = thumbPoints[.thumbCMC]
            else
            {
                return
            }
            
            guard let indexTip = indexPoints[.indexTip], let indexDIP = indexPoints[.indexDIP], let indexPIP = indexPoints[.indexPIP], let indexMCP = indexPoints[.indexMCP]
            else
            {
                return
            }
            
            // Ignore low confidence points.
            guard thumbTipPoint.confidence > 0.3 && thumbBasePoint.confidence > 0.3 && thumbIP_p.confidence > 0.3 && thumbMP_p.confidence > 0.3
            else
            {
                return
            }
            
            // Ignore low confidence points.
            guard indexTip.confidence > 0.3 && indexDIP.confidence > 0.3 && indexPIP.confidence > 0.3 && indexMCP.confidence > 0.3
            else
            {
                return
            }
            
            // Convert points from Vision coordinates to AVFoundation coordinates.
            thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            
            thumbIP = CGPoint(x: thumbIP_p.location.x, y: 1 - thumbIP_p.location.y)
            
            thumbMP = CGPoint(x: thumbMP_p.location.x, y: 1 - thumbMP_p.location.y)
            
            thumbBase = CGPoint(x: thumbBasePoint.location.x, y: 1 - thumbBasePoint.location.y)
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

