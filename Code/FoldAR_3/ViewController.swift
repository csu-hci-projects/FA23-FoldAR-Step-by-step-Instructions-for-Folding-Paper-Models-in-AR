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

class ViewController: UIViewController, ARSCNViewDelegate
{
    // This is the AR SceneKit view class
    // uses device camera for live video feed
    // this is what synchornizes the virtual and real world "views"
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Set the view's delegate
        // TODO: what is this
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // TODO: what other parameters to sceneView here that we can play with?
        sceneView.showsStatistics = true
        
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

    // MARK: - ARSCNViewDelegate
    
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
        planeNode.geometry?.firstMaterial?.diffuse.contents = "testPlane.png"

//         `SCNPlane` is vertically oriented in its local coordinate space, so
//         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        planeNode.eulerAngles.x = -.pi / 2

        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 1

//      Add the plane visualization to the ARKit-managed node so that it tracks
//      changes in the plane anchor as plane estimation continues.
        node.addChildNode(planeNode)
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
