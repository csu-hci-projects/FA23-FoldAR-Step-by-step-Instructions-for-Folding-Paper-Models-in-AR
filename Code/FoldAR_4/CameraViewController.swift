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
    
    // processPoints - IMPORTANT
    // TODO: process points for all fingers + wrist
    func processPoints(thumbTip: CGPoint?, thumbBase: CGPoint?, thumbIP_p: CGPoint?, thumbMP_p: CGPoint?,
                       thumbTip2: CGPoint?, thumbBase2: CGPoint?, thumbIP_p2: CGPoint?, thumbMP_p2: CGPoint?,
                       indexTip1: CGPoint?, indexPIP1: CGPoint?, indexDIP1: CGPoint?, indexMCP1: CGPoint?,
                       indexTip2: CGPoint?, indexPIP2: CGPoint?, indexDIP2: CGPoint?, indexMCP2: CGPoint?)
    {
        // Check that we havea all thumb points
        // Do we need to put the rest of the digits here?
        guard let thumbPoint = thumbTip, let basePoint = thumbBase, let tIPpoint = thumbIP_p, let tMPpoint = thumbMP_p
//              let thumbPoint2 = thumbTip2, let basePoint2 = thumbBase2, let tIPpoint2 = thumbIP_p2, let tMPpoint2 = thumbMP_p2
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
        
        // the ! force unwrap might be best here.
        let thumbPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: thumbTip2!)
        let basePointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: thumbBase2!)
        let tIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: thumbIP_p2!)
        let tMPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: thumbMP_p2!)
        
        let indexTipPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexTip1!)
        let indexPIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexPIP1!)
        let indexDIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexDIP1!)
        let indexMCPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexMCP1!)
        
        let indexTipPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexTip2!)
        let indexPIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexPIP2!)
        let indexDIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexDIP2!)
        let indexMCPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexMCP2!)
        
        // Process new points
        gestureProcessor.processPointsPair((thumbPointConverted, basePointConverted, tIPPointConverted, tMPPointConverted,
                                            thumbPointConverted2, basePointConverted2, tIPPointConverted2, tMPPointConverted2,
                                            indexTipPointConverted, indexPIPPointConverted, indexDIPPointConverted, indexMCPPointConverted,indexTipPointConverted2, indexPIPPointConverted2, indexDIPPointConverted2, indexMCPPointConverted2))
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
        
        // this is what renders the points on the live view
        cameraView.showPoints([pointsPair.thumbTip, pointsPair.thumbBase, pointsPair.thumbIP, pointsPair.thumbMP,
                               pointsPair.thumbTip2, pointsPair.thumbBase2, pointsPair.thumbIP2, pointsPair.thumbMP2,
                               pointsPair.indexTip, pointsPair.indexPIP, pointsPair.indexDIP, pointsPair.indexMCP,
                               pointsPair.indexTip2, pointsPair.indexPIP2, pointsPair.indexDIP2, pointsPair.indexMCP2], color: tipsColor)
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
        
        var thumbTip2: CGPoint?
        var thumbBase2: CGPoint?
        var thumbIP2: CGPoint?
        var thumbMP2: CGPoint?
        
        var indexTip1: CGPoint?
        var indexDIP1: CGPoint?
        var indexPIP1: CGPoint?
        var indexMCP1: CGPoint?
        
        var indexTip2: CGPoint?
        var indexDIP2: CGPoint?
        var indexPIP2: CGPoint?
        var indexMCP2: CGPoint?
        
        defer
        {
            DispatchQueue.main.sync
            {
                self.processPoints(thumbTip: thumbTip, thumbBase: thumbBase, thumbIP_p: thumbIP, thumbMP_p: thumbMP,
                                   thumbTip2: thumbTip2, thumbBase2: thumbBase2, thumbIP_p2: thumbIP2, thumbMP_p2: thumbMP2,
                                   indexTip1: indexTip1, indexPIP1: indexDIP1, indexDIP1: indexPIP1, indexMCP1: indexMCP1,
                                   indexTip2: indexTip2, indexPIP2: indexDIP2, indexDIP2: indexPIP2, indexMCP2: indexMCP2)
            }
        }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first, let observation2 = handPoseRequest.results?.last
            else
            {
                return
            }
            
            // Get points for entire hand
            let thumbPoints = try observation.recognizedPoints(.thumb)
            let indexPoints = try observation.recognizedPoints(.indexFinger)
            let middlePoints = try observation.recognizedPoints(.middleFinger)
            let ringPoints = try observation.recognizedPoints(.ringFinger)
            let pinkyPoints = try observation.recognizedPoints(.littleFinger)
            
            let thumbPoints2 = try observation2.recognizedPoints(.thumb)
            let indexPoints2 = try observation2.recognizedPoints(.indexFinger)
            let middlePoints2 = try observation2.recognizedPoints(.middleFinger)
            let ringPoints2 = try observation2.recognizedPoints(.ringFinger)
            let pinkyPoints2 = try observation2.recognizedPoints(.littleFinger)
//            let wristPoint = try observation.recognizedPoint(.wrist)
            
            guard let thumbTipPoint = thumbPoints[.thumbTip], let thumbIP_p = thumbPoints[.thumbIP], let thumbMP_p = thumbPoints[.thumbMP], let thumbBasePoint = thumbPoints[.thumbCMC]
            else
            {
                return
            }
            
            guard let thumbTipPoint2 = thumbPoints2[.thumbTip], let thumbIP_p2 = thumbPoints2[.thumbIP], let thumbMP_p2 = thumbPoints2[.thumbMP], let thumbBasePoint2 = thumbPoints2[.thumbCMC]
            else
            {
                return
            }
            
            guard let indexTip = indexPoints[.indexTip], let indexDIP = indexPoints[.indexDIP], let indexPIP = indexPoints[.indexPIP], let indexMCP = indexPoints[.indexMCP]
            else
            {
                return
            }
            
            guard let indexTipT = indexPoints2[.indexTip], let indexDIPT = indexPoints2[.indexDIP], let indexPIPT = indexPoints2[.indexPIP], let indexMCPT = indexPoints2[.indexMCP]
            else
            {
                return
            }
            
            guard let middleTip = middlePoints[.middleTip], let middleDIP = middlePoints[.middleDIP], let middlePIP = middlePoints[.middlePIP], let middleMCP = middlePoints[.middleMCP]
            else
            {
                return
            }
            
            guard let ringTip = ringPoints[.ringTip], let ringDIP = ringPoints[.ringDIP], let ringPIP = ringPoints[.ringPIP], let ringMCP = ringPoints[.ringMCP]
            else
            {
                return
            }
            
            guard let pinkyTip = pinkyPoints[.littleTip], let pinkyDIP = pinkyPoints[.littleDIP], let pinkyPIP = pinkyPoints[.littlePIP], let pinkyMCP = pinkyPoints[.littleMCP]
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
            guard thumbTipPoint2.confidence > 0.3 && thumbBasePoint2.confidence > 0.3 && thumbIP_p2.confidence > 0.3 && thumbMP_p2.confidence > 0.3
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
            // Ignore low confidence points.
            guard indexTipT.confidence > 0.3 && indexDIPT.confidence > 0.3 && indexPIPT.confidence > 0.3 && indexMCPT.confidence > 0.3
            else
            {
                return
            }
            
            // Ignore low confidence points.
            guard ringTip.confidence > 0.3 && ringDIP.confidence > 0.3 && ringPIP.confidence > 0.3 && ringMCP.confidence > 0.3
            else
            {
                return
            }
            
            // Ignore low confidence points.
            guard middleTip.confidence > 0.3 && middleDIP.confidence > 0.3 && middlePIP.confidence > 0.3 && middleMCP.confidence > 0.3
            else
            {
                return
            }
            
            // Ignore low confidence points.
            guard pinkyTip.confidence > 0.3 && pinkyDIP.confidence > 0.3 && pinkyPIP.confidence > 0.3 && pinkyMCP.confidence > 0.3
            else
            {
                return
            }
            
            // Convert points from Vision coordinates to AVFoundation coordinates.
            thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            thumbIP = CGPoint(x: thumbIP_p.location.x, y: 1 - thumbIP_p.location.y)
            thumbMP = CGPoint(x: thumbMP_p.location.x, y: 1 - thumbMP_p.location.y)
            thumbBase = CGPoint(x: thumbBasePoint.location.x, y: 1 - thumbBasePoint.location.y)
            
            thumbTip2 = CGPoint(x: thumbTipPoint2.location.x, y: 1 - thumbTipPoint2.location.y)
            thumbIP2 = CGPoint(x: thumbIP_p2.location.x, y: 1 - thumbIP_p2.location.y)
            thumbMP2 = CGPoint(x: thumbMP_p2.location.x, y: 1 - thumbMP_p2.location.y)
            thumbBase2 = CGPoint(x: thumbBasePoint2.location.x, y: 1 - thumbBasePoint2.location.y)
            
            indexTip1 = CGPoint(x: indexTip.location.x, y: 1 - indexTip.location.y)
            indexDIP1 = CGPoint(x: indexDIP.location.x, y: 1 - indexDIP.location.y)
            indexPIP1 = CGPoint(x: indexPIP.location.x, y: 1 - indexPIP.location.y)
            indexMCP1 = CGPoint(x: indexMCP.location.x, y: 1 - indexMCP.location.y)
            
            indexTip2 = CGPoint(x: indexTipT.location.x, y: 1 - indexTipT.location.y)
            indexDIP2 = CGPoint(x: indexDIPT.location.x, y: 1 - indexDIPT.location.y)
            indexPIP2 = CGPoint(x: indexPIPT.location.x, y: 1 - indexPIPT.location.y)
            indexMCP2 = CGPoint(x: indexMCPT.location.x, y: 1 - indexMCPT.location.y)
            
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

