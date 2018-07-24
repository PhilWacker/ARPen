//
//  Plugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

/**
 The Plugin protocol. If you want to write a new plugin you must use this protocol.
 */
protocol Plugin {
    
    var pluginImage : UIImage? { get }
    var pluginIdentifier : String { get }
    var currentScene : PenScene? {get set}
    var currentView : UIView? {get set}
    /**
     This method must be implemented by all plugins.
     Params:
     - scene: The current PenScene instance. There you can find a lot state information about the pen.
     - buttons: An array of all buttons and there state. If buttons[.Button1] is true, then the buttons is pressed at the moment.
     */
    func didUpdateFrame(scene: PenScene, buttons: [Button: Bool])
    
    
    func activatePlugin(withScene scene: PenScene, andView view: UIView)
    func deactivatePlugin()
}
