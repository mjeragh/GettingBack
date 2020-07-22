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
    var boundingBuffer, localRaysBuffer : MTLBuffer!
    var parameters : [Float] = []
    
    override init(sceneSize: CGSize) {
        sphere = Primitive(shape: .sphere, size: 1.0)
        box = Primitive(shape: .cube, size: 1.0)
        super.init(sceneSize: sceneSize)
       buildAccelerationStructure()
      
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
        add(node: box)
        
        camera.position = [0,0,-15]
        camera.name = "Test"
        
        for _ in 0...renderables.count{
            parameters.append(0.0)
        }
    }
    override func updateScene(deltaTime: Float) {
        time += 0.1
        
        box.position = [-1.5 + cos(time),0.5 + sin(time),0]
        sphere.position = [cos(time),0,0 + sin(time)]
    }
    
    override func buildAccelerationStructure() {
        
        //creating Bounding Buffer
       boundingBuffer = Renderer.device.makeBuffer(length: boundingBoxes.count * MemoryLayout<MDLAxisAlignedBoundingBox>.stride, options: .storageModeShared)
        
        var pointer = boundingBuffer?.contents().bindMemory(to: MDLAxisAlignedBoundingBox.self, capacity: boundingBoxes.count)
        
        for boundingBox in boundingBoxes {
            pointer?.pointee.maxBounds = boundingBox.maxBounds
            pointer?.pointee.minBounds = boundingBox.minBounds
            pointer = pointer?.advanced(by: 1) //from page 451 metalbytutorialsV2
        }
        
        let accelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()

        // Create geometry descriptor(s)
        let geometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()

        geometryDescriptor.boundingBoxBuffer = boundingBuffer
        geometryDescriptor.boundingBoxCount = boundingBoxes.count
//        geometryDescriptor.boundingBoxBufferOffset = 0
//        geometryDescriptor.boundingBoxStride = MemoryLayout<MDLAxisAlignedBoundingBox>.stride

        accelerationStructureDescriptor.geometryDescriptors = [ geometryDescriptor ]
        
        //Second Step from the Video of wwdc2020
        // Query for acceleration structure sizes
        let sizes = Renderer.device.accelerationStructureSizes(descriptor: accelerationStructureDescriptor)

        // Allocate acceleration structure
         accelerationStructure =
            Renderer.device.makeAccelerationStructure(size: Int(sizes.accelerationStructureSize))!

//        // Allocate scratch buffer
//        let scratchBuffer = Renderer.device.makeBuffer(length: Int(sizes.buildScratchBufferSize),
//                                              options: .storageModePrivate)!
//
//
//
//        // Create command buffer/encoder
//        let commandBuffer = Renderer.commandQueue.makeCommandBuffer()!
//        let commandEncoder = commandBuffer.makeAccelerationStructureCommandEncoder()!
//
//        // Encode acceleration structure build
//        commandEncoder.build(accelerationStructure: accelerationStructure,
//                             descriptor: accelerationStructureDescriptor,
//                             scratchBuffer: scratchBuffer,
//                             scratchBufferOffset: 0)
//
//        // Commit command buffer
//        commandEncoder.endEncoding()
//        commandBuffer.commit()
    }
    
    override func handleInteraction(at point: CGPoint) {
       
        
        
        let width = Float(sceneSize.width)
        let height = Float(sceneSize.height)
        // let aspectRatio = camera?.aspect//width / height
        
        let projectionMatrix = camera.projectionMatrix
        let inverseProjectionMatrix = projectionMatrix.inverse
        
       // let viewMatrix = camera.worldTransform.inverse
        let inverseViewMatrix = camera.inverseViewMatrix//viewMatrix.inverse
        
        let clipX = (2 * Float(point.x)) / width - 1
        let clipY = 1 - (2 * Float(point.y)) / height
        let clipCoords = SIMD4<Float>(clipX, clipY, 0, 1) // Assume clip space is hemicube, -Z is into the screen
        
        var eyeRayDir = inverseProjectionMatrix * clipCoords
        eyeRayDir.z = 1
        eyeRayDir.w = 0
        
        var worldRayDir = (inverseViewMatrix * eyeRayDir).xyz
        worldRayDir = normalize(worldRayDir)
        
        let eyeRayOrigin = SIMD4<Float>(x: 0, y: 0, z: 0, w: 1)
        let worldRayOrigin = (inverseViewMatrix * eyeRayOrigin).xyz
        
//        let ray = Ray(origin: worldRayOrigin, direction: worldRayDir)
        let commandQueue = Renderer.device.makeCommandQueue()
        commandBuffer = commandQueue!.makeCommandBuffer()
        computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeEncoder?.pushDebugGroup("handleInteraction")
        
        //need to compute the local rays
        var localRays : [localRay] = []
        
        rootNode.children.forEach{node in
            
            localRays.append(localRay(localOrigin: (node.worldTransform.inverse * SIMD4<Float>(worldRayOrigin,0)).xyz, localDirection: (node.worldTransform.inverse * SIMD4<Float>(worldRayDir,0)).xyz))
            
            
        }
        
        localRaysBuffer = Renderer.device.makeBuffer(bytes: localRays, length: MemoryLayout<localRay>.stride * localRays.count, options: .storageModeShared)
        var uniforms = Uniforms()
        uniforms.origin = worldRayOrigin
        uniforms.direction = worldRayDir
        
        computeEncoder?.setBuffer(boundingBuffer, offset: 0, index: 0)
        computeEncoder?.setBuffer(localRaysBuffer, offset: 0, index: 3)
        computeEncoder?.setBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        computeEncoder?.setBytes(parameters, length: MemoryLayout<Float>.stride * renderables.count, index: 2)
        
        let computeFunction = Renderer.device.makeDefaultLibrary()?.makeFunction(name: "testKernel")!//(name: "raytracingKernel")!
        computePipelineState = try! Renderer.device.makeComputePipelineState(function: computeFunction!)
        computeEncoder?.setComputePipelineState(computePipelineState)
        let threadsPerThreadGrid = MTLSizeMake(Int(renderables.count), 1, 1)
        computeEncoder?.dispatchThreadgroups(threadsPerThreadGrid, threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        computeEncoder?.endEncoding()
        computeEncoder?.popDebugGroup()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        os_log("Hit \(self.parameters) at ")
    }
}
