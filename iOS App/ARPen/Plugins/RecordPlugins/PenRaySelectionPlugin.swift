//
//  PenRaySelectionPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 15.08.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//
//


import Foundation

import Foundation
import ARKit

class PenRaySelectionPlugin: Plugin, UserStudyRecordPluginProtocol {
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "RecordPlugin")
    var pluginIdentifier: String = "PenRaySelection"
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
            //self.previousPoint = nil
            DispatchQueue.main.async {
                self.currentView?.superview?.layer.borderColor = UIColor.red.cgColor
            }
            return
        }
        
        DispatchQueue.main.async {
            self.currentView?.superview?.layer.borderColor = UIColor.white.cgColor
        }
        
        guard let boxes = self.boxes else {return}
        
        boxes.forEach({
            $0.highlightIfPointInside(point: scene.pencilPoint.position)
        })
        
        let pressed = buttons[Button.Button1]! || buttons[Button.Button2]!
        
        if pressed, !self.previousButtonState{
            
            if let activeTargetBox = self.activeTargetBox {
                
                if let arSceneView = self.currentView as? SCNView {
                    //project current pen tip position to screen
                    let projectedPencilPosition = arSceneView.projectPoint(scene.pencilPoint.position)
                    print(projectedPencilPosition.z)
                    let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
                    
                    //cast a ray from that position and find the first ARPenNode
                    let hitResults = arSceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
                    self.saveDateEntry(withTarget: activeTargetBox, projectedCGPoint: projectedCGPoint, andHitTestResults: hitResults)
                    
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
    
    func saveDateEntry(withTarget box : ARPenBoxNode, projectedCGPoint: CGPoint, andHitTestResults hitTestResults : [SCNHitTestResult]) {
        guard let startTime = self.startTimeOfCurrentSelection, let arSceneView = self.currentView as? ARSCNView else {
            print("Start time or currentView was was not set")
            print("Start time: \(String(describing: self.startTimeOfCurrentSelection))")
            print("Current view: \(String(describing: self.currentView))")
            return
        }
        let duration = Date().timeIntervalSince(startTime)
        
        var success = false
        var isOnRay = false
        for (index, hitResult) in hitTestResults.enumerated() {
            if hitResult.node == box {
                isOnRay = true
                if index == 0 {
                    success = true
                } else if index == 1 {
                    if let _ = hitTestResults.first?.node as? ARPenBoxNode {
                        continue
                    } else {
                        success = true
                    }
                }
            }
        }
        
        
        let actualDimension = box.dimension*100
        
        //deviation vector from camera view
        //not relevant for touch conditions
        let deviationVectorInCameraView = SCNVector3Make(0, 0, 0)
        
        //get projected points of the corners
        let positionArray = [box.corners.lbd, box.corners.lfd, box.corners.lbh, box.corners.lfh, box.corners.rbd, box.corners.rfd, box.corners.rbh, box.corners.rfh]
        let projectionArray = positionArray.map({arSceneView.projectPoint($0)})
        
        let deviation : Float
        if isOnRay {
            deviation = 0.0
        } else {
            deviation = self.distance(ofPoint: projectedCGPoint, toProjectedBox: projectionArray)
        }
        
        //size of the projection
        
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
        let deviationInPixels = deviation * 3
        
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
        let deviationInInches = deviationInPixels/ppi
        
        let xSizeInCM = xSizeInInches * 2.54
        let ySizeInCM = ySizeInInches * 2.54
        let deviationInCM = deviationInInches * 2.54
        
        let sizeOfProjection = xSizeInCM * ySizeInCM
        
        let targetMeasurementDict = ["TimeForSelection" : String(describing: duration), "Success" : String(describing: success), "IsOnRay" : String(describing: isOnRay), "Deviation" : String(describing: deviationInCM), "DeviationVectorX" : String(describing: abs(deviationVectorInCameraView.x)), "DeviationVectorY" : String(describing: abs(deviationVectorInCameraView.y)), "DeviationVectorZ" : String(describing: abs(deviationVectorInCameraView.z)), "ProjectedSizeOfTarget" : String(describing: sizeOfProjection), "DimensionOfTarget" : String(describing: actualDimension)]
        self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
    }
    
    func distance(ofPoint point : CGPoint, toProjectedBox projectedCorners : [SCNVector3]) -> Float {
        //create array of CGPoints
        var projectedPointsAsCGPoints = [CGPoint]()
        for projectedPoint in projectedCorners {
            let currentPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
            projectedPointsAsCGPoints.append(currentPoint)
        }
        //calculate convex hull
        let convexHullCalculator = ConvexHullCalculator()
        let convexHullPoints = convexHullCalculator.convexHull(fromPoints: projectedPointsAsCGPoints)
        
        //find the closest adjacent point of the projected shape to the point
        var closestPoint : (Int, CGPoint, Float) = (0, CGPoint(x: 0, y: 0), Float.infinity)
        
        for (index, currentPoint) in convexHullPoints.enumerated() {
            let distanceToPoint = distance(fromPoint: point, toPoint: currentPoint)
            if distanceToPoint < closestPoint.2 {
                closestPoint = (index, currentPoint, distanceToPoint)
            }
        }
        
        //calculate distance of point to line segments from the closest point
        let firstNeighboringPoint = closestPoint.0 == 0 ? convexHullPoints.last! : convexHullPoints[closestPoint.0-1]
        let secondNeighboringPoint = closestPoint.0 == convexHullPoints.count-1 ? convexHullPoints.first! : convexHullPoints[closestPoint.0+1]
        
        let distance1 = distance(fromPoint: point, toLineSegmentBetweenPointA: closestPoint.1, andPointB: firstNeighboringPoint)
        let distance2 = distance(fromPoint: point, toLineSegmentBetweenPointA: closestPoint.1, andPointB: secondNeighboringPoint)
        
        return min(distance1,distance2)
    }
    
    func distance(fromPoint pointA : CGPoint, toPoint pointB : CGPoint) -> Float {
        return sqrtf(powf(Float(pointA.x-pointB.x), 2) + powf(Float(pointA.y-pointB.y), 2))
    }
    
    //calculation taken from https://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
    func distance(fromPoint point : CGPoint, toLineSegmentBetweenPointA pointA : CGPoint, andPointB pointB : CGPoint) -> Float {
        let A = point.x - pointA.x
        let B = point.y - pointA.y
        let C = pointB.x - pointA.x
        let D = pointB.y - pointA.y
        
        let dot = A * C + B * D
        let len_sq = C * C + D * D
        if len_sq == 0 {
            return distance(fromPoint: point, toPoint: pointA)
        }
        var param : CGFloat = -1
        param = dot / len_sq
        
        var xx : CGFloat
        var yy : CGFloat
        
        if (param < 0) {
            xx = pointA.x
            yy = pointA.y
        }
        else if (param > 1) {
            xx = pointB.x
            yy = pointB.y
        }
        else {
            xx = pointA.x + param * C
            yy = pointA.y + param * D
        }
        
        let dx = point.x - xx
        let dy = point.y - yy
        return Float(sqrt(dx * dx + dy * dy))
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
        _ = self.currentScene?.drawingNode.childNodes.map({$0.removeFromParentNode()})
        self.currentScene = nil
        self.finishedView?.removeFromSuperview()
        self.finishedView = nil
        self.currentView?.superview?.layer.borderWidth = 0.0
        self.currentView = nil
    }
}
