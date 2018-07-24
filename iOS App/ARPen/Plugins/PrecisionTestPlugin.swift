//
//  PrecisionTestPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 24.07.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

class PrecisionTestPlugin: Plugin {
    
    var pluginImage : UIImage? = UIImage.init(named: "cross")
    var pluginIdentifier: String = "PrecisionTest"
    var currentScene : PenScene?
    var currentView: UIView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        print(scene)
        
        guard scene.markerFound else {
            self.previousPoint = nil
            return
        }
        let pressed = buttons[Button.Button1]!
        
        if pressed, let previousPoint = self.previousPoint {
            let cylinderNode = SCNNode()
            cylinderNode.buildLineInTwoPointsWithRotation(from: previousPoint, to: scene.pencilPoint.position, radius: 0.001, color: UIColor.red)
            cylinderNode.name = "cylinderLine"
            scene.drawingNode.addChildNode(cylinderNode)
        }
        
        let pressed2 = buttons[Button.Button2]!
        if pressed2 {
            guard let boxNode = scene.drawingNode.childNode(withName: "BoxNode", recursively: false) else {
                var boxNode = SCNNode()
                boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0.0))
                boxNode.name = "BoxNode"
                boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                boxNode.position = scene.pencilPoint.position
                scene.drawingNode.addChildNode(boxNode)
                return
            }
            boxNode.position = scene.pencilPoint.position
            
        }
        
        self.previousPoint = scene.pencilPoint.position
        
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: UIView) {
        self.currentScene = scene
        self.currentView = view
        _ = scene.drawingNode.childNodes.map({$0.removeFromParentNode()})
        var boxNode = SCNNode()
        //center
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0.0))
        boxNode.name = "OriginNode"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        boxNode.position = SCNVector3Make(0, 0.025, 0)
        scene.drawingNode.addChildNode(boxNode)
        
        //left back low
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "LeftBackLow"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        boxNode.position = SCNVector3Make(-0.2, 0.005, -0.3)
        scene.drawingNode.addChildNode(boxNode)
        //left front low
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "LeftFrontLow"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        boxNode.position = SCNVector3Make(-0.2, 0.005, 0.1)
        scene.drawingNode.addChildNode(boxNode)
        //right back low
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "RightBackLow"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        boxNode.position = SCNVector3Make(0.2, 0.005, -0.3)
        scene.drawingNode.addChildNode(boxNode)
        //right front low
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "RightFrontLow"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        boxNode.position = SCNVector3Make(0.2, 0.005, 0.1)
        scene.drawingNode.addChildNode(boxNode)
        //left back high
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "LeftBackHigh"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        boxNode.position = SCNVector3Make(-0.2, 0.405, -0.3)
        scene.drawingNode.addChildNode(boxNode)
        //left front high
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "LeftFrontHigh"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        boxNode.position = SCNVector3Make(-0.2, 0.405, 0.1)
        scene.drawingNode.addChildNode(boxNode)
        //right back high
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "RightBackHigh"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        boxNode.position = SCNVector3Make(0.2, 0.405, -0.3)
        scene.drawingNode.addChildNode(boxNode)
        //right front high
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "RightFrontHigh"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        boxNode.position = SCNVector3Make(0.2, 0.405, 0.1)
        scene.drawingNode.addChildNode(boxNode)
        
        //small target
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0))
        boxNode.name = "SmallTarget"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red: 1, green: 0, blue: 0, alpha: 0.95)
        boxNode.position = SCNVector3Make(-0.1, 0.205, 0)
        scene.drawingNode.addChildNode(boxNode)
        
        //medium target
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0.0))
        boxNode.name = "MediumTarget"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.95)
        boxNode.position = SCNVector3Make(0, 0.205, 0)
        scene.drawingNode.addChildNode(boxNode)
        
        //large target
        boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.03, height: 0.03, length: 0.03, chamferRadius: 0.0))
        boxNode.name = "LargeTarget"
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.95)
        boxNode.position = SCNVector3Make(0.1, 0.205, 0)
        scene.drawingNode.addChildNode(boxNode)
    }
    
}
