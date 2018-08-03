//
//  PenSelectionWithHighlightingPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 03.08.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

import Foundation
import ARKit

class PenSelectionWithHighlightingPlugin: Plugin {
    
    var pluginImage : UIImage? = UIImage.init(named: "cross")
    var pluginIdentifier: String = "PenSelectionWithHighlighting"
    var currentScene : PenScene?
    var currentView: UIView?
    var finishedView : UILabel?
    
    var boxes : [ARPenBoxNode]?
    var activeTargetBox : ARPenBoxNode? {
        didSet {
            oldValue?.isActiveTarget = false
            self.activeTargetBox?.isActiveTarget = true
        }
    }
    var indexOfCurrentTargetBox = 0
    
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
        
        boxes.forEach({$0.highlightIfPointInside(point: scene.pencilPoint.position)})
        
        let pressed = buttons[Button.Button1]! || buttons[Button.Button2]!
        
        if pressed, !self.previousButtonState, let activeTargetBox = self.activeTargetBox {
            if activeTargetBox.isPointInside(point: scene.pencilPoint.position) {
                print("Correct selection")
            } else {
                print("Miss")
            }
            self.indexOfCurrentTargetBox += 1
            if self.indexOfCurrentTargetBox < 3 /*boxes.count*/ {
                self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
            } else {
                self.activeTargetBox = nil
                print("Done")
                DispatchQueue.main.async {
                    self.finishedView = UILabel.init()
                    self.finishedView?.text = "Done"
                    self.finishedView?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
                    self.finishedView?.textColor = UIColor.yellow
                    self.finishedView?.textAlignment = .center
                    self.finishedView?.layer.borderWidth = 20.0
                    self.finishedView?.layer.borderColor = UIColor.yellow.cgColor
                    if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                        finishedView.frame.size = CGSize.init(width: 300, height: 300)
                        finishedView.center = superview.center
                        superview.addSubview(finishedView)
                    }
                }
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
        self.activeTargetBox = self.boxes?.first
        
        
    }
    
    func deactivatePlugin() {
        _ = self.currentScene?.drawingNode.childNodes.map({$0.removeFromParentNode()})
        self.currentScene = nil
        self.finishedView?.removeFromSuperview()
        self.finishedView = nil
        self.currentView?.superview?.layer.borderWidth = 0.0
        self.currentView = nil
    }
}
