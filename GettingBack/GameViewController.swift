//
//  GameViewController.swift
//  GettingBack
//
//  Created by Mohammad Jeragh on 3/12/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

import UIKit
import MetalKit
import os.log
import os.signpost

// Our iOS specific view controller
class GameViewController: UIViewController {

    var renderer: Renderer!
   
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

        
        renderer = Renderer(metalView: mtkView)

        let scene = TestScene(sceneSize: mtkView.bounds.size)
        renderer.scene = scene
    }
}


extension GameViewController {
    static var previousScale: CGFloat = 1
      static var translation = CGPoint(x: 0,y: 0)
    static var selectedNode : Node? = nil
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: view) {
            renderer.scene?.handleInteraction(at: location)
        }
        if let node = GameViewController.selectedNode {
            os_log("selectedNode %s",node.name)
        }
        else {
            GameViewController.translation = touches.first!.location(in: view)
            os_log("No Seleted Node")
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard (GameViewController.selectedNode != nil)  else {
            let newTranslation = touches.first?.location(in: view)
            let delta = float2(Float(newTranslation!.x - GameViewController.translation.x),
                               Float(newTranslation!.y - GameViewController.translation.y))
            
            //scene?.camera.rotate(delta: delta)
            return
        }
        if let location = touches.first?.location(in: view)  {
            let newPosition = renderer.scene?.unproject(at: location)
            GameViewController.selectedNode!.position = newPosition!
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        os_log("end Touches")
        guard (GameViewController.selectedNode != nil)  else {
            return
        }
        
        os_log("selectedNOde %s at location %f,%f,%f",GameViewController.selectedNode!.name,GameViewController.selectedNode!.position.x,GameViewController.selectedNode!.position.y,GameViewController.selectedNode!.position.z)
        GameViewController.selectedNode = nil
    }
    
    
    
}
