//
//  TestScene.swift
//  GettingBack
//
//  Created by Mohammad Jeragh on 7/2/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

import Foundation
import CoreGraphics
class TestScene: Scene {
    var time = Float(0)
    let box, sphere : Primitive
    
    override init(sceneSize: CGSize) {
        sphere = Primitive(shape: .sphere, size: 1.0)
        box = Primitive(shape: .cube, size: 1.0)
        super.init(sceneSize: sceneSize)
    }
    
    override func setupScene() {
        
        sphere.position = [0,0,0]
        //sphere.pivotPosition = [1,2,0]
        sphere.material.baseColor = [1.0, 0, 0]
        sphere.material.metallic = 0.0
        sphere.material.roughness = 0
        sphere.material.shininess = 0.4
        sphere.material.specularColor = [0,0,0]
        sphere.material.secondColor = [1.0,0,1.0]
        sphere.material.ambientOcclusion = [0,0,0]
        sphere.material.gradient = linear
        sphere.name = "sun"
        add(node: sphere)
        
        
        box.position = [-1.5,0.5,0]
        box.rotation = [0, Float(45).degreesToRadians, 0]
        box.material.baseColor = [0, 0.5, 0]
        box.material.secondColor = [1.0,1.0,0.0]
        box.material.metallic = 1.0
        box.material.roughness = 0.0
        box.material.shininess = 0.1
        box.material.specularColor = [0,1.0,0.0]
        box.material.ambientOcclusion = [1.0,1.0,1.0]
        box.name = "cube"
        
        camera.position = [0,0,-15]
        camera.name = "Test"
        
        add(node: box)
    }
    override func updateScene(deltaTime: Float) {
        time += 0.1
        
        box.position = [-1.5 + cos(time),0.5 + sin(time),0]
        sphere.position = [cos(time),0,0 + sin(time)]
    }
    
        }
