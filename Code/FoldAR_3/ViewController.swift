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

class ViewController: UIViewController, ARSCNViewDelegate
{
    // This is the AR SceneKit view class
    // uses device camera for live video feed
    // this is what synchornizes the virtual and real world "views"
    @IBOutlet var sceneView: ARSCNView!
    
    // create a SCNNode to hold the 'current' plane node
    var currentPlaneNode: SCNNode?
    
    // This is the hello world button
    let newButton = UIButton()
    
    let minStep = 1
    let maxStep = 12
    
    var currentStep = 1
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Set the view's delegate
        // TODO: what is this
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // TODO: what other parameters to sceneView here that we can play with?
        sceneView.showsStatistics = true
        
        // create next and back world button
        nextButton()
        backButton()
        stage(cur: currentStep)
        
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        print("Rotated")
    }
    
    // pre-defined functions that don't do anything will be overridden
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // TODO: Lets look at what else is in configuration.
        // is there a way to detect images or tracking images
        // Detect horizontal planes in the scene
        // are we calling this on a different image set each time?
        configuration.planeDetection = .horizontal

        // Run the view's session
        // pass this configuration to the scene view
        sceneView.session.run(configuration)
        
        // what other sceneView.session. are there?
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Perform the edge detection of a sheet of paper
    // Get the height and width from the results of the edge detection
    // update SCNPlane dynamically with the new dimensions
    
    // for every anchor it calls did add on node using the renderer
    // this is one type of renderer, a scene renderer (as opposed to a physics renderer)
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        
        // Place content only for anchors found by plane detection.
        // were going to want to limit the number of papers we detect to one?
        // only create planeAnchor if the anchor passed into renderer is of an ARPlaneAnchor (probably a child of ARAnchor)
        // Are we going to be using a plane anchor or an image anchor?
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        // We now have planeAnchor
        // setting plane which is a type of scene plane with the width and height of the anchor. The anchor is what detects the area of the plane
        let plane = SCNPlane(width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
        
        // Remove the previous plane node
        if let existingPlaneNode = currentPlaneNode
        {
            existingPlaneNode.removeFromParentNode()
        }
        
        // this is the simulation position
        // there is a plane node which it's simulation position is in the center of the plane anchor
        // why is y supposed to be 0 here?
        // defining the scn node's geometery with the plane
        // the SCN Node accepts an plane that is an SCN Plane
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = SIMD3<Float>(planeAnchor.center.x, 0, planeAnchor.center.z)

        // Give the SCNNode a texture from Assets.xcassets to better visualize the detected plane.
        // instead of grid.png this will be our outline with the dotted lines per step
        // this might be interesting to look at other properties of geometry
        if currentStep == maxStep {
            planeNode.geometry?.firstMaterial?.diffuse.contents = "S12.png"
        }else{
            planeNode.geometry?.firstMaterial?.diffuse.contents = "S\(currentStep)p.png"
        }
        

//         `SCNPlane` is vertically oriented in its local coordinate space, so
//         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        planeNode.eulerAngles.x = -.pi / 2

        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 1

//      Add the plane visualization to the ARKit-managed node so that it tracks
//      changes in the plane anchor as plane estimation continues.
        node.addChildNode(planeNode)
        
        currentPlaneNode = planeNode
        
    }
    
    func backButton()
    {
        let newButton = UIButton()
        
        // this is a button action
        newButton.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
        
        // placement of the button
        newButton.frame = CGRect(x: 10, y: 5, width: 70, height: 40);
        newButton.setTitle("Back", for: .normal)
        newButton.setTitleColor(.black, for: .normal)
        newButton.backgroundColor = .red
        newButton.layer.borderColor = UIColor.orange.cgColor
        newButton.layer.borderWidth = 1.5
        
        // gradient in background of button
        let gradientLayer = CAGradientLayer()
        
        // use bounds of button
        gradientLayer.frame = newButton.bounds
        
        // colors, gradient, etc.
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
        
        // this is a button action
        newButton.addTarget(self, action: #selector(self.nextButtonTapped), for: .touchUpInside)
        
        // placement of the button
        newButton.frame = CGRect(x: self.view.bounds.maxX-80, y: 5, width: 70, height: 40);
        newButton.setTitle("Next", for: .normal)
        newButton.setTitleColor(.black, for: .normal)
        newButton.backgroundColor = .orange
        newButton.layer.borderColor = UIColor.red.cgColor
        newButton.layer.borderWidth = 1.5
        
        // gradient in background of button
        let gradientLayer = CAGradientLayer()
        
        // use bounds of button
        gradientLayer.frame = newButton.bounds
        
        // colors, gradient, etc.
        gradientLayer.colors = [UIColor.red.cgColor, UIColor.orange.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y:1.0)
        gradientLayer.locations = [0.0, 1.0]
        
        // add layer to button
        newButton.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(newButton)
    }
    
    func stage(cur: Int, update: Bool = false){
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
    
    // this function prints the message Hello World! to the terminal
    @objc func nextButtonTapped(sender: UIButton)
    {
        if currentStep < maxStep {
            currentStep = currentStep+1
        }
        
        print("Pressed: Next | Current step:", currentStep)
        
        stage(cur: currentStep, update: true)
        
        // remove the current planeNode to show the next one
        currentPlaneNode?.removeFromParentNode()
        currentPlaneNode = nil
        
        stage(cur: currentStep)
        
        // call the configure AR session for the NEXT step
        configureARSession()
    }
    
    @objc func backButtonTapped(sender: UIButton)
    {
        if currentStep > minStep{
            currentStep = currentStep-1
        }
        
        print("Pressed: Back | Current step:", currentStep)
        stage(cur: currentStep, update: true)
        
        // remove the current planeNode to show the next one
        currentPlaneNode?.removeFromParentNode()
        currentPlaneNode = nil
        
        stage(cur: currentStep)
        
        // call the configure AR session for the NEXT step
        configureARSession()
    }
    
    // this function will reset the AR session for the next step.
    // perhaps we can set it up to only detect ONE plane?
    func configureARSession()
    {
        // using session.pause will pause the AR session that's
        // associated with ARSCNView. This just stopps the tracking of the
        // horizontal plane
        sceneView.session.pause()

        // Create a new instance of th a new AR session object
        // and removing the exisiting anchors (from the previous session)
        let configuration = ARWorldTrackingConfiguration()
        
        // reset the configuration settings for the new configuration to
        // horizontal plane detection
        configuration.planeDetection = .horizontal
        
        // run new session and set the option to remove any existing anchors
        // within the scene view (the previous detected horizontal plane)
        sceneView.session.run(configuration, options: [.removeExistingAnchors])
    }
    
    func session(_ session: ARSession, didFailWithError error: Error)
    {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession)
    {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession)
    {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
