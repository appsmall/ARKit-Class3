//
//  ViewController.swift
//  ARDominoes
//
//  Created by apple on 11/05/19.
//  Copyright © 2019 appsmall. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var detectedPlanes: [String: SCNNode] = [:]
    var dominos = [SCNNode]()
    
    var previousDominoPosition: SCNVector3?
    let dominoColors: [UIColor] = [.cyan, .blue, .red, .green, .gray, .orange, .yellow, .magenta]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.debugOptions = [.showFeaturePoints]
        
        // The time interval between updates to the physics simulation.
        // The small this number is, the more accurate the physics simulation will be.
        sceneView.scene.physicsWorld.timeStep = 1/200
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(screenPanned))
        sceneView.addGestureRecognizer(panGesture)
        
        addLight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @objc func screenPanned(gesture: UIPanGestureRecognizer) {
        
        // We need the ground floor to be stable, so we have to disable plane detection first.
        // To disable plane detection, we reconfigure the session and run again.
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        let location = gesture.location(in: sceneView)

        // Any objects are detected, an ARHitTestResult will be returned which we then use to get the exact position.
        guard let hitTestResult = sceneView.hitTest(location, types: .existingPlane).first else {
            return
        }
        
        // Getting currentPostion from ARHitTestResult
        let x = CGFloat(hitTestResult.worldTransform.columns.3.x)
        let y = CGFloat(hitTestResult.worldTransform.columns.3.y)
        let z = CGFloat(hitTestResult.worldTransform.columns.3.z)
        let currentPosition = SCNVector3(x, y, z)
        
        guard let previousPosition = previousDominoPosition else {
            self.previousDominoPosition = currentPosition
            return
        }
        
        let minimumDistanceBetweenDomino: Float = 0.03
        
        let distance = Utility.distanceBetween(point1: previousPosition, andPoint2: currentPosition)
        
        if distance >= minimumDistanceBetweenDomino {
            // We create our dominoes using a simple SCNBox
            let boxGeometry = SCNBox(width: 0.007, height: 0.06, length: 0.03, chamferRadius: 0.0)
            boxGeometry.materials.first?.diffuse.contents = dominoColors.randomElement()
            
            let dominoNode = SCNNode(geometry: boxGeometry)
            dominoNode.position = SCNVector3(currentPosition.x, currentPosition.y + 0.03, currentPosition.z)
            
            // Get the angle between the current domino and the previous domino
            let startingPoint = CGPoint(x: CGFloat(currentPosition.x), y: CGFloat(currentPosition.z))
            let endingPoint = CGPoint(x: CGFloat(previousPosition.x), y: CGFloat(previousPosition.z))
            var currentAngle = Utility.pointPairToBearingDegrees(startingPoint: startingPoint, endingPoint: endingPoint)
            
            // Convert from radians to degrees
            currentAngle *= Float.pi / 180
            
            // Rotate the node along the Y-axis
            dominoNode.rotation = SCNVector4(0, 1, 0, -currentAngle)
            
            // Add physics to our dominoes.
            dominoNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            dominoNode.physicsBody?.mass = 2.0
            dominoNode.physicsBody?.friction = 0.8
            
            sceneView.scene.rootNode.addChildNode(dominoNode)
            dominos.append(dominoNode)
            
            self.previousDominoPosition = currentPosition
        }
    }
    
    func addLight() {
        let light = SCNLight()
        light.type = .directional
        light.intensity = 500
        
        light.castsShadow = true
        light.shadowMode = .deferred
        
        light.shadowColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.5)
        
        let directionalLightNode = SCNNode()
        directionalLightNode.light = light
        directionalLightNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 3)
        sceneView.scene.rootNode.addChildNode(directionalLightNode)
        
        let ambientLight = SCNLight()
        ambientLight.intensity = 50
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        sceneView.scene.rootNode.addChildNode(ambientLightNode)
    }

    @IBAction func removeAllDominosBtnPressed(_ sender: UIButton) {
        for domino in dominos {
            domino.removeFromParentNode()
            self.previousDominoPosition = nil
        }
        
        dominos = []
    }
    
    @IBAction func startBtnPressed(_ sender: UIButton) {
        guard let firstDomino = dominos.first else {
            return
        }
        
        let power: Float = 0.7
        
        let direction = SCNVector3(firstDomino.worldRight.x * power, firstDomino.worldRight.y * power, firstDomino.worldRight.z * power)
        firstDomino.physicsBody?.applyForce(direction, asImpulse: true)
    }
}


// MARK:- ARSCNVIEW DELEGATE METHODS
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        
        let plane = SCNPlane(width: width, height: height)
        //plane.materials.first?.diffuse.contents = UIColor.orange
        plane.firstMaterial?.colorBufferWriteMask = .init(rawValue: 0)
        
        let planeNode = SCNNode(geometry: plane)
        let x = planeAnchor.center.x
        let y = planeAnchor.center.y
        let z = planeAnchor.center.z
        planeNode.position = SCNVector3(x, y, z)
        
        //planeNode.opacity = 0.3
        
        // SCNPlanes are vertical when first created, we have to rotate our plane by 90 degrees
        // pi (in radians) = 3.14 * 57.3 = 180 radians
        // w = 180 / 2 = 90
        planeNode.rotation = SCNVector4(1, 0, 0, -Float.pi/2)
        
        let box = SCNBox(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z), length: 0.001, chamferRadius: 0)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
        node.addChildNode(planeNode)
        
        // Each anchor has an unique identifier.
        // We add the plane node to our dictionary using its unique identifier as the key.
        detectedPlanes[planeAnchor.identifier.uuidString] = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        guard let planeNode = detectedPlanes[planeAnchor.identifier.uuidString] else { return }
        
        if let plane = planeNode.geometry as? SCNPlane {
            plane.width = CGFloat(planeAnchor.extent.x)
            plane.height = CGFloat(planeAnchor.extent.z)
            planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
            
            // Update the physics shape
            let box = SCNBox(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z), length: 0.001, chamferRadius: 0)
            planeNode.physicsBody?.physicsShape = SCNPhysicsShape(geometry: box, options: nil)
        }
    }
}
