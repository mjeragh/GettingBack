//
//  GameViewController.swift
//  GettingBack
//
//  Created by Mohammad Jeragh on 3/12/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

import UIKit
import MetalKit

// Our iOS specific view controller
class GameViewController: UIViewController {

    var renderer: Renderer!
   
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

       
        renderer = Renderer(metalKitView: mtkView)

    }
}
