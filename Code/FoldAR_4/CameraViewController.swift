//
//  CameraViewController.swift
//  FoldAR_4
//
//  Created by Tom Cavey & Tani Cath on 11/02/23.

// Here's a list of all the links that made it possible to build this project.
// A lot of code was used from Apple's documentation, as well as other tutorials,
// sample code, and instructional websites. Without the help of the followoing links
// none of this woul dbe possible to build this project:
// (in no particular order)
// MAIN EXAMPLE: https://developer.apple.com/documentation/vision/detecting_hand_poses_with_vision
// VERY GOOD CODE EXAMPLE: https://betterprogramming.pub/swipeless-tinder-using-ios-14-vision-hand-pose-estimation-64e5f00ce45c
// https://patrickgatewood.com/arkit-research/tutorials/arkit-hello-world/tutorial.html
// https://developer.apple.com/documentation/swiftui/gestures
// https://www.youtube.com/watch?v=NAsQCNpodPI
// https://github.com/JanSteinhauer/CoreMLRecognition/tree/main
// https://developer.apple.com/documentation/scenekit/sceneview/options
// https://developer.apple.com/documentation/scenekit/scnscenerendererdelegate
// https://developer.apple.com/documentation/vision/vndetectdocumentsegmentationrequest
// https://developer.apple.com/documentation/vision/vndetecthumanhandposerequest
// https://medium.com/swift-india/saving-data-in-ios-part-2-a8c9f810d5c
// https://developer.apple.com/documentation/swift/textoutputstream
// https://developer.apple.com/documentation/foundation/filemanager/1410695-createfile
// https://developer.apple.com/documentation/foundation/filemanager
// https://www.swiftyplace.com/blog/file-manager-in-swift-reading-writing-and-deleting-files-and-directories
// https://stackoverflow.com/questions/26989493/how-to-open-file-and-append-a-string-in-it-swift
// https://developer.apple.com/forums/thread/90791
// https://developer.apple.com/documentation/vision/detecting_human_body_poses_in_images
// https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html
// https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/index.html#//apple_ref/doc/uid/TP40007457-CH2-SW1
// https://www.youtube.com/watch?v=AiKBxiHdFYo
// https://betterprogramming.pub/new-in-ios-14-vision-contour-detection-68fd5849816e
// https://developer.apple.com/documentation/vision
// https://developer.apple.com/documentation/vision/building_a_feature-rich_app_for_sports_analysis
// https://developer.apple.com/forums/thread/90791
// https://developer.apple.com/documentation/appkit/nsview/1483783-addsubview

// rotating to landscape
// https://stackoverflow.com/questions/38894031/swift-how-to-detect-orientation-changes


import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController
{
    // CONSTANTS
    private var cameraView: CameraView { view as! CameraView }
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var evidenceBuffer = [HandGestureProcessor.PointsPair]()
    private var lastObservationTimestamp = Date()
    
    private var minConfidence: Float = 0.3
    
    // create a reference to the hand gesture processor
    private var gestureProcessor = HandGestureProcessor()
    
    // this is the story board created functions for button and button actions
    // we tie this to the gestureProcessor.startCollection variable
    // to enable and disable data collection mode
    @IBOutlet weak var beginLogging: UIButton!
    @IBOutlet weak var nameValue: UITextField!
    
    var savedName: String = ""
    var switchState: Int = 0
    
    @IBOutlet weak var fastAccSwitch: UISegmentedControl!
    
    @IBAction func beginButtonPressed(_ sender: UIButton)
    {
        if sender.currentTitle == "START"
        {
            if let text = nameValue.text
            {
                savedName = text
                print("Saved text: \(savedName)")
                nameValue.resignFirstResponder()
                gestureProcessor.savedName = savedName
            }
            
            // fast / accurate switch
            switchState = fastAccSwitch.selectedSegmentIndex
            print(switchState)
            gestureProcessor.switchState = switchState
            
            sender.setTitle("STOP", for: .normal)
            sender.backgroundColor = UIColor.red
            gestureProcessor.startCollection = true
        }
        else
        {
            sender.setTitle("START", for: .normal)
            sender.backgroundColor = UIColor.green
            gestureProcessor.startCollection = false
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Add state change handler to hand gesture processor.
        gestureProcessor.didChangeStateClosure =
        {
            [weak self] state in self?.handleGestureStateChange()
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)

        if let connection = self.cameraView.previewLayer.connection
        {
            let newOrientation: AVCaptureVideoOrientation

            if UIDevice.current.orientation.isLandscape
            {
                // supporst both left and right landscape.
                if UIDevice.current.orientation == .landscapeLeft
                {
                    newOrientation = .landscapeRight
                }
                else
                {
                    newOrientation = .landscapeLeft
                }
            }
            else
            {
                newOrientation = .portrait
            }

            if connection.isVideoOrientationSupported
            {
                connection.videoOrientation = newOrientation
            }
        }
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
    func processPoints(thumbPoints: [CGPoint?], thumbPoints2: [CGPoint?], indexPoints: [CGPoint?], indexPoints2: [CGPoint?],
                       middlePoints: [CGPoint?], middlePoints2: [CGPoint?], ringPoints: [CGPoint?], ringPoints2:[CGPoint?], littlePoints: [CGPoint?], littlePoints2: [CGPoint?])
    {
        let thumbTip = thumbPoints[0]
        let thumbBase = thumbPoints[1]
        let thumbIP_p = thumbPoints[2]
        let thumbMP_p = thumbPoints[3]
        let thumbTip2 = thumbPoints2[0]
        let thumbBase2 = thumbPoints2[1]
        let thumbIP_p2 = thumbPoints2[2]
        let thumbMP_p2 = thumbPoints2[3]
        
        let indexTip1p = indexPoints[0]
        let indexPIP1p = indexPoints[1]
        let indexDIP1p = indexPoints[2]
        let indexMCP1p = indexPoints[3]
        let indexTip2p = indexPoints2[0]
        let indexPIP2p = indexPoints2[1]
        let indexDIP2p = indexPoints2[2]
        let indexMCP2p = indexPoints2[3]
        
        let middleTip1p = middlePoints[0]
        let middlePIP1p = middlePoints[1]
        let middleDIP1p = middlePoints[2]
        let middleMCP1p = middlePoints[3]
        let middleTip2p = middlePoints2[0]
        let middlePIP2p = middlePoints2[1]
        let middleDIP2p = middlePoints2[2]
        let middleMCP2p = middlePoints2[3]
        
        let ringTip1p = ringPoints[0]
        let ringPIP1p = ringPoints[1]
        let ringDIP1p = ringPoints[2]
        let ringMCP1p = ringPoints[3]
        let ringTip2p = ringPoints2[0]
        let ringPIP2p = ringPoints2[1]
        let ringDIP2p = ringPoints2[2]
        let ringMCP2p = ringPoints2[3]
        
        let littleTip1p = littlePoints[0]
        let littlePIP1p = littlePoints[1]
        let littleDIP1p = littlePoints[2]
        let littleMCP1p = littlePoints[3]
        let littleTip2p = littlePoints2[0]
        let littlePIP2p = littlePoints2[1]
        let littleDIP2p = littlePoints2[2]
        let littleMCP2p = littlePoints2[3]
        
        // Check that we havea all thumb points
        // Do we need to put the rest of the digits here?
        guard let thumbPoint = thumbTip, let basePoint = thumbBase, let tIPpoint = thumbIP_p, let tMPpoint = thumbMP_p
        else
        {
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
        
        let indexTipPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexTip1p!)
        let indexPIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexPIP1p!)
        let indexDIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexDIP1p!)
        let indexMCPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexMCP1p!)
        
        let indexTipPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexTip2p!)
        let indexPIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexPIP2p!)
        let indexDIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexDIP2p!)
        let indexMCPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: indexMCP2p!)
        
        let middleTipPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: middleTip1p!)
        let middlePIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: middlePIP1p!)
        let middleDIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: middleDIP1p!)
        let middleMCPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: middleMCP1p!)
        
        let middleTipPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: middleTip2p!)
        let middlePIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: middlePIP2p!)
        let middleDIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: middleDIP2p!)
        let middleMCPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: middleMCP2p!)
        
        let ringTipPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringTip1p!)
        let ringPIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringPIP1p!)
        let ringDIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringDIP1p!)
        let ringMCPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringMCP1p!)
        
        let ringTipPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringTip2p!)
        let ringPIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringPIP2p!)
        let ringDIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringDIP2p!)
        let ringMCPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: ringMCP2p!)
        
        let littleTipPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: littleTip1p!)
        let littlePIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: littlePIP1p!)
        let littleDIPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: littleDIP1p!)
        let littleMCPPointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: littleMCP1p!)
        
        let littleTipPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: littleTip2p!)
        let littlePIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: littlePIP2p!)
        let littleDIPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: littleDIP2p!)
        let littleMCPPointConverted2 = previewLayer.layerPointConverted(fromCaptureDevicePoint: littleMCP2p!)
        
        // Process new points
        gestureProcessor.processPointsPair((thumbPointConverted, basePointConverted, tIPPointConverted, tMPPointConverted,
                                            thumbPointConverted2, basePointConverted2, tIPPointConverted2, tMPPointConverted2,
                                            indexTipPointConverted, indexPIPPointConverted, indexDIPPointConverted, indexMCPPointConverted,
                                            indexTipPointConverted2, indexPIPPointConverted2, indexDIPPointConverted2, indexMCPPointConverted2,
                                            middleTipPointConverted, middlePIPPointConverted, middleDIPPointConverted, middleMCPPointConverted,
                                            middleTipPointConverted2, middlePIPPointConverted2, middleDIPPointConverted2, middleMCPPointConverted2,
                                            ringTipPointConverted, ringPIPPointConverted, ringDIPPointConverted, ringMCPPointConverted,
                                            ringTipPointConverted2, ringPIPPointConverted2, ringDIPPointConverted2, ringMCPPointConverted2,
                                            littleTipPointConverted, littlePIPPointConverted, littleDIPPointConverted, littleMCPPointConverted,
                                            littleTipPointConverted2, littlePIPPointConverted2, littleDIPPointConverted2, littleMCPPointConverted2))
    }
    
    
    
    private func handleGestureStateChange()
    {
        let pointsPair = gestureProcessor.lastProcessedPointsPair
        
        // this is what renders the points on the live view
        cameraView.showPoints([pointsPair.thumbTip, pointsPair.thumbBase, pointsPair.thumbIP, pointsPair.thumbMP,
                               pointsPair.thumbTip2, pointsPair.thumbBase2, pointsPair.thumbIP2, pointsPair.thumbMP2,
                               pointsPair.indexTip, pointsPair.indexPIP, pointsPair.indexDIP, pointsPair.indexMCP,
                               pointsPair.indexTip2, pointsPair.indexPIP2, pointsPair.indexDIP2, pointsPair.indexMCP2,
                               pointsPair.middleTip, pointsPair.middlePIP, pointsPair.middleDIP, pointsPair.middleMCP,
                               pointsPair.middleTip2, pointsPair.middlePIP2, pointsPair.middleDIP2, pointsPair.middleMCP2,
                               pointsPair.ringTip, pointsPair.ringPIP, pointsPair.ringDIP, pointsPair.ringMCP,
                               pointsPair.ringTip2, pointsPair.ringPIP2, pointsPair.ringDIP2, pointsPair.ringMCP2,
                               pointsPair.littleTip, pointsPair.littlePIP, pointsPair.littleDIP, pointsPair.littleMCP,
                               pointsPair.littleTip2, pointsPair.littlePIP2, pointsPair.littleDIP2, pointsPair.littleMCP2],
                              color: .green)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate
{
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
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
        
        var middleTip1: CGPoint?
        var middlePIP1: CGPoint?
        var middleDIP1: CGPoint?
        var middleMCP1: CGPoint?
        
        var middleTip2: CGPoint?
        var middlePIP2: CGPoint?
        var middleDIP2: CGPoint?
        var middleMCP2: CGPoint?
        
        var ringTip1: CGPoint?
        var ringPIP1: CGPoint?
        var ringDIP1: CGPoint?
        var ringMCP1: CGPoint?
        
        var ringTip2: CGPoint?
        var ringPIP2: CGPoint?
        var ringDIP2: CGPoint?
        var ringMCP2: CGPoint?
        
        var littleTip1: CGPoint?
        var littlePIP1: CGPoint?
        var littleDIP1: CGPoint?
        var littleMCP1: CGPoint?
        
        var littleTip2: CGPoint?
        var littlePIP2: CGPoint?
        var littleDIP2: CGPoint?
        var littleMCP2: CGPoint?
        
        defer
        {
            DispatchQueue.main.sync
            {
                self.processPoints(thumbPoints: [thumbTip, thumbBase, thumbIP, thumbMP],
                                   thumbPoints2: [thumbTip2, thumbBase2, thumbIP2, thumbMP2],
                                   indexPoints: [indexTip1, indexPIP1, indexDIP1, indexMCP1],
                                   indexPoints2: [indexTip2, indexPIP2, indexDIP2, indexMCP2],
                                   middlePoints: [middleTip1, middlePIP1, middleDIP1, middleMCP1],
                                   middlePoints2: [middleTip2, middlePIP2, middleDIP2, middleMCP2],
                                   ringPoints: [ringTip1, ringPIP1, ringDIP1, ringMCP1],
                                   ringPoints2: [ringTip2, ringPIP2, ringDIP2, ringMCP2],
                                   littlePoints: [littleTip1, littlePIP1, littleDIP1, littleMCP1],
                                   littlePoints2: [littleTip2, littlePIP2, littleDIP2, littleMCP2])
            }
        }

        // Create the VN Image Request Handler so we have access to the live video frames to perform the
        // VNDetectHumanHandPoseRequest on
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
        do
        {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            
            // Continue only when a hand was detected in the frame
            // This will attempt to find the first hand, and then the second hand
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
            let littlePoints = try observation.recognizedPoints(.littleFinger)
            
            let thumbPoints2 = try observation2.recognizedPoints(.thumb)
            let indexPoints2 = try observation2.recognizedPoints(.indexFinger)
            let middlePoints2 = try observation2.recognizedPoints(.middleFinger)
            let ringPoints2 = try observation2.recognizedPoints(.ringFinger)
            let littlePoints2 = try observation2.recognizedPoints(.littleFinger)
            
            // skipping wrist points for now
//            let wristPoint = try observation.recognizedPoint(.wrist)
//            let wristPoint2 = try observation2.recognizedPoint(.wrist)
            
            // Thumb fingers for both hands
            guard let thumbTipPoint = thumbPoints[.thumbTip],
                  let thumbIP_p = thumbPoints[.thumbIP],
                  let thumbMP_p = thumbPoints[.thumbMP],
                  let thumbBasePoint = thumbPoints[.thumbCMC]
            else
            {
                return
            }
            
            guard let thumbTipPoint2 = thumbPoints2[.thumbTip],
                  let thumbIP_p2 = thumbPoints2[.thumbIP],
                  let thumbMP_p2 = thumbPoints2[.thumbMP],
                  let thumbBasePoint2 = thumbPoints2[.thumbCMC]
            else
            {
                return
            }
            
            // Index fingers for both hands
            guard let indexTip1p = indexPoints[.indexTip],
                    let indexDIP1p = indexPoints[.indexDIP],
                    let indexPIP1p = indexPoints[.indexPIP],
                    let indexMCP1p = indexPoints[.indexMCP]
            else
            {
                return
            }
            guard let indexTip2p = indexPoints2[.indexTip],
                  let indexDIP2p = indexPoints2[.indexDIP],
                  let indexPIP2p = indexPoints2[.indexPIP],
                  let indexMCP2p = indexPoints2[.indexMCP]
            else
            {
                return
            }
            
            // Middle fingers for both hands
            guard let middleTip1p = middlePoints[.middleTip],
                  let middleDIP1p = middlePoints[.middleDIP],
                  let middlePIP1p = middlePoints[.middlePIP],
                  let middleMCP1p = middlePoints[.middleMCP]
            else
            {
                return
            }
            guard let middleTip2p = middlePoints2[.middleTip],
                  let middleDIP2p = middlePoints2[.middleDIP],
                  let middlePIP2p = middlePoints2[.middlePIP],
                  let middleMCP2p = middlePoints2[.middleMCP]
            else
            {
                return
            }
            
            // Ring fingers for both hands
            guard let ringTip1p = ringPoints[.ringTip],
                  let ringDIP1p = ringPoints[.ringDIP],
                  let ringPIP1p = ringPoints[.ringPIP],
                  let ringMCP1p = ringPoints[.ringMCP]
            else
            {
                return
            }
            guard let ringTip2p = ringPoints2[.ringTip],
                  let ringDIP2p = ringPoints2[.ringDIP],
                  let ringPIP2p = ringPoints2[.ringPIP],
                  let ringMCP2p = ringPoints2[.ringMCP]
            else
            {
                return
            }
            
            // Little fingers for both hands
            guard let littleTip1p = littlePoints[.littleTip],
                  let littleDIP1p = littlePoints[.littleDIP],
                  let littlePIP1p = littlePoints[.littlePIP],
                  let littleMCP1p = littlePoints[.littleMCP]
            else
            {
                return
            }
            guard let littleTip2p = littlePoints2[.littleTip],
                  let littleDIP2p = littlePoints2[.littleDIP],
                  let littlePIP2p = littlePoints2[.littlePIP],
                  let littleMCP2p = littlePoints2[.littleMCP]
            else
            {
                return
            }
            
            
            
            // Get the confidence level for all points, exclude if it's below 30%
            guard thumbTipPoint.confidence > minConfidence &&
                    thumbBasePoint.confidence > minConfidence &&
                    thumbIP_p.confidence > minConfidence &&
                    thumbMP_p.confidence > minConfidence
            else
            {
                return
            }
            guard thumbTipPoint2.confidence > minConfidence &&
                    thumbBasePoint2.confidence > minConfidence &&
                    thumbIP_p2.confidence > minConfidence &&
                    thumbMP_p2.confidence > minConfidence
            else
            {
                return
            }
            

            guard indexTip1p.confidence > minConfidence
                    && indexDIP1p.confidence > minConfidence
                    && indexPIP1p.confidence > minConfidence
                    && indexMCP1p.confidence > minConfidence
            else
            {
                return
            }
            guard indexTip2p.confidence > minConfidence &&
                    indexDIP2p.confidence > minConfidence &&
                    indexPIP2p.confidence > minConfidence &&
                    indexMCP2p.confidence > minConfidence
            else
            {
                return
            }

            guard ringTip1p.confidence > minConfidence &&
                    ringDIP1p.confidence > minConfidence &&
                    ringPIP1p.confidence > minConfidence &&
                    ringMCP1p.confidence > minConfidence
            else
            {
                return
            }
            guard ringTip2p.confidence > minConfidence &&
                    ringDIP2p.confidence > minConfidence &&
                    ringPIP2p.confidence > minConfidence &&
                    ringMCP2p.confidence > minConfidence
            else
            {
                return
            }
            
            // Ignore low confidence points.
            guard middleTip1p.confidence > minConfidence &&
                    middleDIP1p.confidence > minConfidence &&
                    middlePIP1p.confidence > minConfidence &&
                    middleMCP1p.confidence > minConfidence
            else
            {
                return
            }
            guard middleTip2p.confidence > minConfidence &&
                    middleDIP2p.confidence > minConfidence &&
                    middlePIP2p.confidence > minConfidence &&
                    middleMCP2p.confidence > minConfidence
            else
            {
                return
            }
            
            guard littleTip1p.confidence > minConfidence &&
                    littleDIP1p.confidence > minConfidence &&
                    littlePIP1p.confidence > minConfidence &&
                    littleMCP1p.confidence > minConfidence
            else
            {
                return
            }
            guard littleTip2p.confidence > minConfidence &&
                    littleDIP2p.confidence > minConfidence &&
                    littlePIP2p.confidence > minConfidence &&
                    littleMCP2p.confidence > minConfidence
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
            
            indexTip1 = CGPoint(x: indexTip1p.location.x, y: 1 - indexTip1p.location.y)
            indexDIP1 = CGPoint(x: indexDIP1p.location.x, y: 1 - indexDIP1p.location.y)
            indexPIP1 = CGPoint(x: indexPIP1p.location.x, y: 1 - indexPIP1p.location.y)
            indexMCP1 = CGPoint(x: indexMCP1p.location.x, y: 1 - indexMCP1p.location.y)
            
            indexTip2 = CGPoint(x: indexTip2p.location.x, y: 1 - indexTip2p.location.y)
            indexDIP2 = CGPoint(x: indexDIP2p.location.x, y: 1 - indexDIP2p.location.y)
            indexPIP2 = CGPoint(x: indexPIP2p.location.x, y: 1 - indexPIP2p.location.y)
            indexMCP2 = CGPoint(x: indexMCP2p.location.x, y: 1 - indexMCP2p.location.y)
            
            middleTip1 = CGPoint(x: middleTip1p.location.x, y: 1 - middleTip1p.location.y)
            middleDIP1 = CGPoint(x: middleDIP1p.location.x, y: 1 - middleDIP1p.location.y)
            middlePIP1 = CGPoint(x: middlePIP1p.location.x, y: 1 - middlePIP1p.location.y)
            middleMCP1 = CGPoint(x: middleMCP1p.location.x, y: 1 - middleMCP1p.location.y)
            
            middleTip2 = CGPoint(x: middleTip2p.location.x, y: 1 - middleTip2p.location.y)
            middleDIP2 = CGPoint(x: middleDIP2p.location.x, y: 1 - middleDIP2p.location.y)
            middlePIP2 = CGPoint(x: middlePIP2p.location.x, y: 1 - middlePIP2p.location.y)
            middleMCP2 = CGPoint(x: middleMCP2p.location.x, y: 1 - middleMCP2p.location.y)
            
            ringTip1 = CGPoint(x: ringTip1p.location.x, y: 1 - ringTip1p.location.y)
            ringDIP1 = CGPoint(x: ringDIP1p.location.x, y: 1 - ringDIP1p.location.y)
            ringPIP1 = CGPoint(x: ringPIP1p.location.x, y: 1 - ringPIP1p.location.y)
            ringMCP1 = CGPoint(x: ringMCP1p.location.x, y: 1 - ringMCP1p.location.y)
            
            ringTip2 = CGPoint(x: ringTip2p.location.x, y: 1 - ringTip2p.location.y)
            ringDIP2 = CGPoint(x: ringDIP2p.location.x, y: 1 - ringDIP2p.location.y)
            ringPIP2 = CGPoint(x: ringPIP2p.location.x, y: 1 - ringPIP2p.location.y)
            ringMCP2 = CGPoint(x: ringMCP2p.location.x, y: 1 - ringMCP2p.location.y)
            
            littleTip1 = CGPoint(x: littleTip1p.location.x, y: 1 - littleTip1p.location.y)
            littleDIP1 = CGPoint(x: littleDIP1p.location.x, y: 1 - littleDIP1p.location.y)
            littlePIP1 = CGPoint(x: littlePIP1p.location.x, y: 1 - littlePIP1p.location.y)
            littleMCP1 = CGPoint(x: littleMCP1p.location.x, y: 1 - littleMCP1p.location.y)
            
            littleTip2 = CGPoint(x: littleTip2p.location.x, y: 1 - littleTip2p.location.y)
            littleDIP2 = CGPoint(x: littleDIP2p.location.x, y: 1 - littleDIP2p.location.y)
            littlePIP2 = CGPoint(x: littlePIP2p.location.x, y: 1 - littlePIP2p.location.y)
            littleMCP2 = CGPoint(x: littleMCP2p.location.x, y: 1 - littleMCP2p.location.y)
            
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

