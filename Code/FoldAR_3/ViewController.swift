//
//  ViewController.swift
//  FoldAR_3
//
//  Created by Tom Cavey on 10/25/23.
//

// Things we want to know:
// ! -> optional
// let scene = SCNScene(named: "art.scnassets/ship.scn")!
//sceneView.scene = scene

import UIKit
import SceneKit
import ARKit
import CoreImage
import CoreGraphics
import Vision

class ViewController: UIViewController, ARSCNViewDelegate
{
    @IBOutlet var sceneView: ARSCNView!
    
// https://developer.apple.com/documentation/vision/detecting_hand_poses_with_vision
//    var cameraView : SCNCamera!
    
    var currentPlaneNode: SCNNode?
    var initialPlaneDimensions: (width: CGFloat, height: CGFloat)?
    var initialPlanePosition: SIMD3<Float>?
    var currentStep = 1
    let minStep = 1
    let maxStep = 12
    
    // Initialization of the scene view
    // How is this different from viewLoad()
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        nextButton()
        backButton()
        
        stage(cur: currentStep)
    }
    
    // fix later
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()

        // issue #28
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // Render selected image on detected horizontal plane. Anchor is passed in.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        if initialPlaneDimensions == nil || currentStep == minStep
        {
            initialPlaneDimensions = (width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
        }
        
        if initialPlanePosition == nil || currentStep == minStep
        {
            initialPlanePosition = SIMD3<Float>(planeAnchor.center.x, 0, planeAnchor.center.z)
        }
        
        let plane = SCNPlane(width: initialPlaneDimensions!.width, height: initialPlaneDimensions!.height)
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.simdPosition = initialPlanePosition!
        
        if currentStep == maxStep
        {
            planeNode.geometry?.firstMaterial?.diffuse.contents = "S12.png"
        }
        else
        {
            planeNode.geometry?.firstMaterial?.diffuse.contents = "S\(currentStep)p.png"
        }
        
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 1
        
        node.addChildNode(planeNode)

        if let existingPlaneNode = currentPlaneNode
        {
            existingPlaneNode.removeFromParentNode()
        }
        
        currentPlaneNode = planeNode
    }
    
    //    // Render for the scene renderer. Will run on multiple anchors if found
    //    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    //    {
    //        var planeNode = SCNNode()
    //
    //        if currentStep == minStep
    //        {
    //            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    //
    //            initialPlaneDimensions = (width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
    //            initialPlanePosition   = SIMD3<Float>(planeAnchor.center.x, 0, planeAnchor.center.z)
    //
    //            let plane = SCNPlane(width: initialPlaneDimensions!.width, height: initialPlaneDimensions!.height)
    //            planeNode = SCNNode(geometry: plane)
    //
    //            planeNode.simdPosition = initialPlanePosition!
    //        }
    //
    //        if currentStep == maxStep
    //        {
    //            planeNode.geometry?.firstMaterial?.diffuse.contents = "S12.png"
    //        }
    //        else
    //        {
    //            planeNode.geometry?.firstMaterial?.diffuse.contents = "S\(currentStep)p.png"
    //        }
    //
    //        planeNode.eulerAngles.x = -.pi / 2
    //        planeNode.opacity = 1
    //        node.addChildNode(planeNode)
    //    }
    
    func backButton()
    {
        let newButton = UIButton()
        newButton.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
        newButton.frame = CGRect(x: 10, y: 5, width: 70, height: 40);
        newButton.setTitle("Back", for: .normal)
        newButton.setTitleColor(.black, for: .normal)
        newButton.backgroundColor = .red
        newButton.layer.borderColor = UIColor.orange.cgColor
        newButton.layer.borderWidth = 1.5
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = newButton.bounds
        gradientLayer.colors = [UIColor.orange.cgColor, UIColor.red.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y:1.0)
        gradientLayer.locations = [0.0, 1.0]
        newButton.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(newButton)
    }
    
    func nextButton()
    {
        let newButton = UIButton()
        newButton.addTarget(self, action: #selector(self.nextButtonTapped), for: .touchUpInside)
        newButton.frame = CGRect(x: self.view.bounds.maxX-80, y: 5, width: 70, height: 40);
        newButton.setTitle("Next", for: .normal)
        newButton.setTitleColor(.black, for: .normal)
        newButton.backgroundColor = .orange
        newButton.layer.borderColor = UIColor.red.cgColor
        newButton.layer.borderWidth = 1.5
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = newButton.bounds
        gradientLayer.colors = [UIColor.red.cgColor, UIColor.orange.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y:1.0)
        gradientLayer.locations = [0.0, 1.0]
        newButton.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(newButton)
    }
    
    func stage(cur: Int, update: Bool = false)
    {
        let stage = UILabel()
        stage.frame = CGRect(x: 100, y: 5, width: 40, height: 40)
        stage.center.x = self.view.center.x
        stage.text = String(cur)
        stage.font = .boldSystemFont(ofSize: 14)
        stage.textColor = .black
        stage.textAlignment = .center
        stage.backgroundColor = .white
        
        if update{
            view.willRemoveSubview(stage)
        }
        
        view.addSubview(stage)
    }
    
    @objc func nextButtonTapped(sender: UIButton)
    {
        if currentStep < maxStep {
            currentStep = currentStep+1
        }
        
        print("Pressed: Next | Current step:", currentStep)
        
        stage(cur: currentStep, update: true)

        configureARSession()
    }
    
    @objc func backButtonTapped(sender: UIButton)
    {
        if currentStep > minStep{
            currentStep = currentStep-1
        }
        
        print("Pressed: Back | Current step:", currentStep)
        stage(cur: currentStep, update: true)
        
        configureARSession()
    }
    
    func configureARSession()
    {
        sceneView.session.pause()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.removeExistingAnchors])
    }
    
    func detectHandPosition(in image: CVPixelBuffer)
    {
        // try using the Human Hand detection API
        let detectedHand = VNDetectHumanHandPoseRequest()
        
        detectedHand.maximumHandCount = 1
        // look at: y coordinate of the handLandmarkKeyThumbTIP
        // handLandmarkKeyThumbCMC
    }
}
