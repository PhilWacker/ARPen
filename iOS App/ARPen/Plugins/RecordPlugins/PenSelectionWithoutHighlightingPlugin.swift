//
//  PenSelectionWithoutHighlightingPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 06.08.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

import Foundation
import ARKit

class PenSelectionWithoutHighlightingPlugin: Plugin, UserStudyRecordPluginProtocol {
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "RecordPlugin")
    var pluginIdentifier: String = "PenWithoutHighlighting"
    var currentScene : PenScene?
    var currentView: UIView?
    var finishedView : UILabel?
    
    var boxes : [ARPenBoxNode]?
    var activeTargetBox : ARPenBoxNode? {
        didSet {
            oldValue?.isActiveTarget = false
            self.activeTargetBox?.isActiveTarget = true
            self.startTimeOfCurrentSelection = Date()
        }
    }
    var indexOfCurrentTargetBox = 0
    
    //data recording
    var startTimeOfCurrentSelection : Date?
    
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    private var previousButtonState = false
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        guard scene.markerFound else {
            self.previousPoint = nil
            DispatchQueue.main.async {
                self.currentView?.superview?.layer.borderColor = UIColor.red.cgColor
            }
            return
        }
        
        DispatchQueue.main.async {
            self.currentView?.superview?.layer.borderColor = UIColor.white.cgColor
        }
        
        guard let boxes = self.boxes else {return}
        
        //no hightlighting of selection in this condition
        //boxes.forEach({$0.highlightIfPointInside(point: scene.pencilPoint.position)})
        
        let pressed = buttons[Button.Button1]! || buttons[Button.Button2]!
        
        if pressed, !self.previousButtonState{
            
            if let activeTargetBox = self.activeTargetBox {
                
                self.saveDateEntry(withTarget: activeTargetBox, inScene: scene)
                
                //activate next target
                self.indexOfCurrentTargetBox += 1
                if self.indexOfCurrentTargetBox < boxes.count {
                    self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
                } else {
                    self.activeTargetBox = nil
                    print("Done")
                    DispatchQueue.main.async {
                        self.finishedView?.text = "Done"
                        if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                            superview.addSubview(finishedView)
                        }
                    }
                }
            } else if self.indexOfCurrentTargetBox < boxes.count {
                DispatchQueue.main.async {
                    self.finishedView?.removeFromSuperview()
                }
                self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
            }
        }
        
        
        self.previousPoint = scene.pencilPoint.position
        self.previousButtonState = pressed
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: UIView) {
        self.currentScene = scene
        self.currentView = view
        self.currentView?.superview?.layer.borderWidth = 10.0
        
        self.fillSceneWithCubes(scene: scene)
        
        self.currentScene?.pencilPoint.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        
    }
    
    
    func fillSceneWithCubes(scene : PenScene) {
        let sceneConstructor = ARPenSceneConstructor.init()
        self.boxes = sceneConstructor.preparedARPenBoxNodes()
        
        self.boxes?.forEach({scene.drawingNode.addChildNode($0)})
        
        self.indexOfCurrentTargetBox = 0
        //        self.activeTargetBox = self.boxes?.first
        
        DispatchQueue.main.async {
            self.finishedView = UILabel.init()
            self.finishedView?.text = "Press a button to start"
            self.finishedView?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            self.finishedView?.textColor = UIColor.yellow
            self.finishedView?.textAlignment = .center
            self.finishedView?.layer.borderWidth = 20.0
            self.finishedView?.layer.borderColor = UIColor.yellow.cgColor
            if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                finishedView.frame.size = CGSize.init(width: 500, height: 300)
                finishedView.center = superview.center
                superview.addSubview(finishedView)
            }
        }
        
    }
    
    func saveDateEntry(withTarget box : ARPenBoxNode, inScene scene : PenScene) {
        guard let startTime = self.startTimeOfCurrentSelection, let arSceneView = self.currentView as? ARSCNView else {
            print("Start time or currentView was was not set")
            print("Start time: \(String(describing: self.startTimeOfCurrentSelection))")
            print("Current view: \(String(describing: self.currentView))")
            return
        }
        let duration = Date().timeIntervalSince(startTime)
        
        let success : Bool
        if box.isPointInside(point: scene.pencilPoint.position) {
            success = true
        } else {
            success = false
        }
        
        let deviation = box.distance(ofPoint: scene.pencilPoint.position)*100
        
        let actualDimension = box.dimension*100
        
        //deviation vector from camera view
        let deviationVectorInWorldView = SCNVector3Make(box.position.x - scene.pencilPoint.position.x, box.position.y - scene.pencilPoint.position.y , box.position.z - scene.pencilPoint.position.z)
        var deviationVectorInCameraView = SCNVector3Make(0, 0, 0)
        if let cameraNode = arSceneView.pointOfView, !success {
            deviationVectorInCameraView = scene.drawingNode.convertVector(deviationVectorInWorldView, to: cameraNode)
        }
        deviationVectorInCameraView.x *= 100
        deviationVectorInCameraView.y *= 100
        deviationVectorInCameraView.z *= 100
        
        //size of the projection
        
        //get projected points of the corners
        let positionArray = [box.corners.lbd, box.corners.lfd, box.corners.lbh, box.corners.lfh, box.corners.rbd, box.corners.rfd, box.corners.rbh, box.corners.rfh]
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
            switch UIScreen.main.nativeBounds.height {
            case 1334:
                //print("iPhone 6/6S/7/8")
                ppi = 326
            case 2208, 1920:
                //print("iPhone 6+/6S+/7+/8+")
                ppi = 401
                xSizeInPixels /= 1.15
                ySizeInPixels /= 1.15
            case 2436:
                //print("iPhone X")
                ppi = 458
            default:
                print("unknown device type")
            }
        }
        
        let xSizeInInches = xSizeInPixels/ppi
        let ySizeInInches = ySizeInPixels/ppi
        
        let xSizeInCM = xSizeInInches * 2.54
        let ySizeInCM = ySizeInInches * 2.54
        
        let sizeOfProjection = xSizeInCM * ySizeInCM
        
        let targetMeasurementDict = ["TimeForSelection" : String(describing: duration), "Success" : String(describing: success), "Deviation" : String(describing: deviation), "DeviationVectorX" : String(describing: deviationVectorInCameraView.x), "DeviationVectorY" : String(describing: deviationVectorInCameraView.y), "DeviationVectorZ" : String(describing: deviationVectorInCameraView.z), "ProjectedSizeOfTarget" : String(describing: sizeOfProjection), "DimensionOfTarget" : String(describing: actualDimension)]
        self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
    }
    
    func lastTrialWasMarkedAsAnOutlier() {
        if self.indexOfCurrentTargetBox > 0 {
            self.indexOfCurrentTargetBox -= 1
        }
        self.activeTargetBox = nil
        DispatchQueue.main.async {
            self.finishedView?.text = "Press a button to continue"
            if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                superview.addSubview(finishedView)
            }
        }
    }
    
    func deactivatePlugin() {
        self.activeTargetBox = nil
        self.currentScene?.pencilPoint.geometry?.materials.first?.diffuse.contents = UIColor.red
        _ = self.currentScene?.drawingNode.childNodes.map({$0.removeFromParentNode()})
        self.currentScene = nil
        self.finishedView?.removeFromSuperview()
        self.finishedView = nil
        self.currentView?.superview?.layer.borderWidth = 0.0
        self.currentView = nil
    }
}

