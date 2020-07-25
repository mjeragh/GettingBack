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

class TestScene: Scene {
    var time = Float(0)
    let box, sphere : Primitive
    var commandBuffer : MTLCommandBuffer!
    var computePipelineState: MTLComputePipelineState!
    var computeEncoder: MTLComputeCommandEncoder!
    var accelerationStructure: MTLAccelerationStructure!
    var nodeGPUBuffer : MTLBuffer!
    let width : Float
    let height : Float
    
    override init(sceneSize: CGSize) {
        sphere = Primitive(shape: .sphere, size: 1.0)
        box = Primitive(shape: .cube, size: 1.0)
        width = Float(sceneSize.width)
        height = Float(sceneSize.height)
        super.init(sceneSize: sceneSize)
        
       buildAccelerationStructure()
      
    }
    
    override func setupScene() {
        
        sphere.position = [1,3.3,10]
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
        
        
        
        box.position = [1,1.5,0]
        box.rotation = [0, Float(45).degreesToRadians, 0]
        box.material.baseColor = [0, 0.5, 0]
        box.material.secondColor = [1.0,1.0,0.0]
        box.material.metallic = 1.0
        box.material.roughness = 0.0
        box.material.shininess = 0.1
        box.material.specularColor = [0,1.0,0.0]
        box.material.ambientOcclusion = [1.0,1.0,1.0]
        box.name = "cube"
        add(node: box)
        add(node: sphere)
        currentCameraIndex = 1
        camera.position = [0,0,-15]
        camera.name = "Standard Camera"
        
        currentCameraIndex = 0
        (cameras[0] as! ArcballCamera).distance = 15
        currentCameraIndex = 0
       
        if let tp = touchPlane.debugPlane {
            
            add(node: tp)
            
        }
        
    }
    override func updateScene(deltaTime: Float) {
//        time += 0.1
//
//        box.position = [-1.5 + cos(time),0.5 + sin(time),0]
//        sphere.position = [cos(time),0,0 + sin(time)]
    }
    
    //the function name should change to build buffers
    override func buildAccelerationStructure() {
        
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
        
        //need to compute the local rays
        var pointer = nodeGPUBuffer?.contents().bindMemory(to: NodeGPU.self, capacity: rootNode.children.count)
        rootNode.children.forEach{node in
            
            node.nodeGPU.localRay = (LocalRay(localOrigin: (node.worldTransform.inverse * SIMD4<Float>(worldRayOrigin,1)).xyz, localDirection: (node.worldTransform.inverse * SIMD4<Float>(worldRayDir,0)).xyz))
            node.nodeGPU.parameter = 10000000000.0
            pointer?.pointee = node.nodeGPU
            pointer = pointer?.advanced(by: 1) //from page 451 metalbytutorialsV2
        }
        
        
        var uniforms = Uniforms()
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
