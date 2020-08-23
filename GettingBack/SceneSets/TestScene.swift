//
//  TestScene.swift
//  GettingBack
//
//  Created by Mohammad Jeragh on 7/2/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

import Foundation
import CoreGraphics
import MetalPerformanceShaders
import MetalKit
import OSLog

let debugRenderBoundingBox = true

class TestScene: Scene {
    
    
    var commandBuffer : MTLCommandBuffer!
    var computePipelineState: MTLComputePipelineState!
    var computeEncoder: MTLComputeCommandEncoder!
    var nodeGPUBuffer : MTLBuffer!
    let width : Float
    let height : Float
    
    
    override init(sceneSize: CGSize) {
       
        width = Float(sceneSize.width)
        height = Float(sceneSize.height)
       
        super.init(sceneSize: sceneSize)
        touchPlane = Plane(a: 0,b: 1.57,c: 0,d: -2, debug: false)
        fragmentUniforms.lightCount = lighting.count
       buildGPUBuffers()
      
    }
    
    override func setupScene() {
//        let box, sphere : Primitive
//        sphere = Primitive(shape: .sphere, size: 1.0)
//        box = Primitive(shape: .cube, size: 1.0)
//        
//        sphere.position = [1,0,10]
//        //sphere.pivotPosition = [1,2,0]
//        sphere.material.baseColor = [1.0, 0, 0]
//        sphere.material.metallic = 0.0
//        sphere.material.roughness = 0
//        sphere.material.shininess = 0.4
//        sphere.material.specularColor = [0,0,0]
//        sphere.material.secondColor = [0.0,0,1.0]
//        sphere.material.ambientOcclusion = [0,0,0]
//        sphere.material.gradient = radial
//        sphere.name = "sun"
//        add(node: sphere)
//        
//        
//        box.position = [1,0,0]
//        box.rotation = [0, Float(45).degreesToRadians, 0]
//        box.material.baseColor = [0, 0.5, 0]
//        box.material.secondColor = [1.0,1.0,0.0]
//        box.material.metallic = 1.0
//        box.material.roughness = 0.0
//        box.material.shininess = 0.1
//        box.material.specularColor = [0,1.0,0.0]
//        box.material.ambientOcclusion = [1.0,1.0,1.0]
//        box.name = "cube"
//        add(node: box)
                
//        let wagon = Model(name: "wheelbarrow.usdz")
//        wagon.position = [0,0,0]
//        wagon.scale = [0.01,0.01,0.01]
//        wagon.name = "Wagon"
//        add(node: wagon)
        
//        let train = Model(name: "train.obj")
//        train.name = "train"
//        train.position = [0, -1, 4]
//        train.rotation = [0, Float(45).degreesToRadians, 0]
//        add(node: train)
        
//        let beachball = Model(name: "beachball.usda")
//        beachball.position = [1,1,0]
//        beachball.scale = [2.1,2.1,2.1]
//        beachball.name = "beachball"
//        beachball.animationPaused = true
//        add(node: beachball)
        
//        let toyCar = Model(name: "toy_car.usdz")
//
//        toyCar.position = [0,2,4]
//        toyCar.scale = [0.1,0.1,0.1]
//        toyCar.name = "toyCar"
//        add(node: toyCar)
        
        let drummer = Model(name:"skeleton.usda")
        drummer.scale = [100,100,100]
        drummer.rotation = [.pi / 2, .pi, 0]
        drummer.name = "drummer"
        drummer.runAnimation(name: "wave")
        drummer.animationPaused = false
        add(node: drummer)
        
       
        
        
       
        
        
        
        
        
        currentCameraIndex = 1
        camera.position = [0,0,-15]
        camera.name = "Standard Camera"
        
        
        
        
        
        currentCameraIndex = 0
        (cameras[0] as! ArcballCamera).distance = 15
        (cameras[0] as! ArcballCamera).rotation.x = Float(-10).degreesToRadians
        
        
        
        

        
    }
    override func updateScene(deltaTime: Float) {
     currentTime += deltaTime

    }
    
    //the function name should change to build buffers
    override func buildGPUBuffers() {
        
        //creating Bounding Buffer
       nodeGPUBuffer = Renderer.device.makeBuffer(length: rootNode.children.count * MemoryLayout<NodeGPU>.stride, options: .storageModeShared)
     
  
    }
    
    override func sceneSizeWillChange(to size: CGSize) {
        super.sceneSizeWillChange(to: size)
        
        
    }
    
    override func handleInteraction(at point: CGPoint) {
       
        let clipX = (2 * Float(point.x)) / width - 1
        let clipY = 1 - (2 * Float(point.y)) / height
        let clipCoords = SIMD4<Float>(clipX, clipY, 0, 1) // Assume clip space is hemicube, -Z is into the screen
        
        var eyeRayDir = camera.projectionMatrix.inverse * clipCoords
        eyeRayDir.z = 1
        eyeRayDir.w = 0
        
        var worldRayDir = (camera.inverseViewMatrix * eyeRayDir).xyz
        worldRayDir = normalize(worldRayDir)
        
       
        let eyeRayOrigin = SIMD4<Float>(x: 0, y: 0, z: 0, w: 1)
        let worldRayOrigin = (camera.inverseViewMatrix * eyeRayOrigin).xyz
        
        
        let commandQueue = Renderer.device.makeCommandQueue()
        commandBuffer = commandQueue!.makeCommandBuffer()
        computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeEncoder?.pushDebugGroup("handleInteraction")
        let gpuCapacity = renderables.count
        //need to compute the local rays
        var pointer = nodeGPUBuffer?.contents().bindMemory(to: NodeGPU.self, capacity: gpuCapacity)
        rootNode.children.forEach{node in
            node.nodeGPU.localRay = (LocalRay(localOrigin: (node.worldTransform.inverse * SIMD4<Float>(worldRayOrigin,1)).xyz, localDirection: (node.worldTransform.inverse * SIMD4<Float>(worldRayDir,0)).xyz))
//            node.nodeGPU.parameter = 10000000000.0
            pointer?.pointee = node.nodeGPU
            pointer = pointer?.advanced(by: 1) //from page 451 metalbytutorialsV2
            
        }
        
        
//        var uniforms = Uniforms()
        uniforms.origin = worldRayOrigin
        uniforms.direction = worldRayDir
        
        
        
        computeEncoder?.setBuffer(nodeGPUBuffer, offset: 0, index: 0)
        

        
        
        computeEncoder?.setBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
       
        let computeFunction = Renderer.device.makeDefaultLibrary()?.makeFunction(name: "testKernel")!//(name: "raytracingKernel")!
        computePipelineState = try! Renderer.device.makeComputePipelineState(function: computeFunction!)
        computeEncoder?.setComputePipelineState(computePipelineState)
        let threadsPerThreadGrid = MTLSizeMake(Int(renderables.count), 1, 1)
        computeEncoder?.dispatchThreadgroups(threadsPerThreadGrid, threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        computeEncoder?.endEncoding()
        computeEncoder?.popDebugGroup()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        pointer = nodeGPUBuffer?.contents().bindMemory(to: NodeGPU.self, capacity: rootNode.children.count)
       
        
        for node in rootNode.children {
            node.nodeGPU = pointer!.pointee
            
            
//            os_log("\((node.name) as String), \((node.nodeGPU.parameter) as Float), \(Int32((node.nodeGPU.debug) as Int32))")
            pointer = pointer?.advanced(by: 1)
        }
        
        let answer = rootNode.children.min{
            a, b in a.nodeGPU.parameter < b.nodeGPU.parameter
        }
        if (answer?.nodeGPU.debug == 2 ){
            os_log("Hit \((answer?.name)! as String) , \((answer?.nodeGPU.parameter)! as Float), \(Int32((answer?.nodeGPU.debug)! as Int32))")
            GameViewController.selectedNode = answer
        } else{
            os_log("Miss")
        }
    }
    
    
    
    override func unproject(at point: CGPoint) -> SIMD3<Float>? {
        
        let clipX = (2 * Float(point.x)) / width - 1
        let clipY = 1 - (2 * Float(point.y)) / height
        let clipCoords = SIMD4<Float>(clipX, clipY, 0, 1) // Assume clip space is hemicube, -Z is into the screen
        
        var eyeRayDir = camera.projectionMatrix.inverse * clipCoords
        eyeRayDir.z = 1
        eyeRayDir.w = 0
        
        var worldRayDir = (camera.inverseViewMatrix * eyeRayDir).xyz
        worldRayDir = normalize(worldRayDir)
        
        

        
        let eyeRayOrigin = SIMD4<Float>(x: 0, y: 0, z: 0, w: 1)
        let worldRayOrigin = (camera.inverseViewMatrix * eyeRayOrigin).xyz
        
        let ray = LocalRay(localOrigin: worldRayOrigin, localDirection: worldRayDir)
       os_log("ray.direction %f, %f, %f",ray.localDirection.x, ray.localDirection.y, ray.localDirection.z)
     
        var position  = GameViewController.selectedNode!.position
        
        let parameter = touchPlane.intersectionPlane(ray)
        os_log("parameter: %f", parameter)
        if (parameter  > Float(0.0)) {
            
            position = ray.localOrigin + ray.localDirection * parameter
            os_log("(unproject) intersectionPoint %f, %f, %f", ray.localDirection.x * parameter, ray.localDirection.y * parameter, ray.localDirection.z * parameter)
           // position.y += 0
        }
        return position
    }
    
}
