//
//  PrecisionTestPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 24.07.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class PrecisionTestPlugin: Plugin {
    
    var pluginImage : UIImage? = UIImage.init(named: "cross")
    var pluginIdentifier: String = "PrecisionTest"
    var currentScene : PenScene?
    var currentView: UIView?
    
    var boxes : [ARPenBoxNode]?
    
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        guard scene.markerFound else {
            self.previousPoint = nil
            return
        }
        
        boxes?.forEach({$0.highlightIfPointInside(point: scene.pencilPoint.position)})
        
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
        
        self.fillSceneWithCubes(scene: scene)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.currentView?.addGestureRecognizer(tapRecognizer)
        self.currentView?.isUserInteractionEnabled = true
    }
    
    @objc func handleTap(_ sender:UITapGestureRecognizer){
        if sender.state == .ended {
            print("Tap Recognized")
            let touchPoint = sender.location(in: self.currentView)
            
            guard let sceneView = self.currentView as? SCNView else { return }
            let hitResults = sceneView.hitTest(touchPoint, options: nil)
            
            if let firstItem = hitResults.first {
                print(firstItem.node.name)
                let boundingBox = firstItem.node.boundingBox
                
                //calculate corners of the cube
                //l = left, r = right, b = back, f = front, d = down, h = high
                let nodePosition = firstItem.node.position
                let lbd = SCNVector3Make(nodePosition.x + boundingBox.min.x, nodePosition.y + boundingBox.min.y, nodePosition.z + boundingBox.min.z)
                let lfd = SCNVector3Make(nodePosition.x + boundingBox.min.x, nodePosition.y + boundingBox.min.y, nodePosition.z + boundingBox.max.z)
                let rbd = SCNVector3Make(nodePosition.x + boundingBox.max.x, nodePosition.y + boundingBox.min.y, nodePosition.z + boundingBox.min.z)
                let rfd = SCNVector3Make(nodePosition.x + boundingBox.max.x, nodePosition.y + boundingBox.min.y, nodePosition.z + boundingBox.max.z)
                
                let lbh = SCNVector3Make(nodePosition.x + boundingBox.min.x, nodePosition.y + boundingBox.max.y, nodePosition.z + boundingBox.min.z)
                let lfh = SCNVector3Make(nodePosition.x + boundingBox.min.x, nodePosition.y + boundingBox.max.y, nodePosition.z + boundingBox.max.z)
                let rbh = SCNVector3Make(nodePosition.x + boundingBox.max.x, nodePosition.y + boundingBox.max.y, nodePosition.z + boundingBox.min.z)
                let rfh = SCNVector3Make(nodePosition.x + boundingBox.max.x, nodePosition.y + boundingBox.max.y, nodePosition.z + boundingBox.max.z)
                
                //test if the positions are correct
                var sphereNode : SCNNode
                var positionArray = [lbd, lfd, rbd, rfd, lbh, lfh, rbh, rfh]
                for x in 0..<8 {
                    sphereNode = SCNNode.init(geometry: SCNSphere.init(radius: 0.005))
                    sphereNode.name = "Corner\(x)"
                    sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    let position = positionArray[x]
                    sphereNode.position = position
                    self.currentScene?.drawingNode.addChildNode(sphereNode)
                }
                
                if let arSceneView = self.currentView as? ARSCNView {
                    //get projected points of the corners
                    let projectionArray = positionArray.map({arSceneView.projectPoint($0)})
                    
                    var minX : Float = Float.infinity
                    var maxX : Float = 0
                    var minY : Float = Float.infinity
                    var maxY : Float = 0
                    
                    for position in projectionArray {
                        if position.x < minX {minX = position.x}
                        if position.x > maxX {maxX = position.x}
                        if position.y < minY {minY = position.y}
                        if position.y > maxY {maxY = position.y}
                    }
                    
                    //get device type
                    let xSizeInPoints = maxX - minX
                    let ySizeInPoints = maxY - minY
                    var xSizeInPixels = xSizeInPoints * 3
                    var ySizeInPixels = ySizeInPoints * 3
                    
                    var ppi : Float = 0
                    
                    if UIDevice().userInterfaceIdiom == .phone {
                        print("Height: \(UIScreen.main.nativeBounds.height)")
                        switch UIScreen.main.nativeBounds.height {
                        case 1334:
                            print("iPhone 6/6S/7/8")
                            ppi = 326
                        case 2208, 1920:
                            print("iPhone 6+/6S+/7+/8+")
                            ppi = 401
                            xSizeInPixels /= 1.15
                            ySizeInPixels /= 1.15
                        case 2436:
                            print("iPhone X")
                            ppi = 458
                        default:
                            print("unknown phone")
                        }
                    }
                    
                    let xSizeInInches = xSizeInPixels/ppi
                    let ySizeInInches = ySizeInPixels/ppi
                    
                    let xSizeInCM = xSizeInInches * 2.54
                    let ySizeInCM = ySizeInInches * 2.54
                    
                    let sizeOfProjection = xSizeInCM * ySizeInCM
                    
                    print(xSizeInCM)
                    print(ySizeInCM)
                    
                    if let mainView = self.currentView?.superview {
                        let newView = UIView.init(frame: CGRect.init(x: Double(minX), y: Double(minY), width: Double(maxX - minX), height: Double(maxY - minY)))
                        newView.backgroundColor = UIColor.white
                        mainView.addSubview(newView)
                        // draw rect from projectedMin to projectedMax
                    }
                    
                }
            }
        }
        
    }
    
    func fillSceneWithCubes(scene : PenScene) {
        let sceneConstructor = ARPenSceneConstructor.init()
        self.boxes = sceneConstructor.preparedARPenBoxNodes()
        
        self.boxes?.forEach({scene.drawingNode.addChildNode($0)})
        
    }
    
    func deactivatePlugin() {
        _ = self.currentScene?.drawingNode.childNodes.map({$0.removeFromParentNode()})
        self.currentScene = nil
        self.currentView = nil
    }
}
