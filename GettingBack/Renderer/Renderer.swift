//
//  Renderer.swift
//  GettingBack
//
//  Created by Mohammad Jeragh on 3/12/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

// The 256 byte aligned size of our uniform structure
let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100

let maxBuffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var colorPixelFormat: MTLPixelFormat!
    static var library: MTLLibrary?
//    var dynamicUniformBuffer: MTLBuffer
//    var pipelineState: MTLRenderPipelineState
    var depthStencilState: MTLDepthStencilState!
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    var sphere, box : Primitive!
    // Camera holds view and projection matrices
    lazy var camera: Camera = {
        let camera = Camera()
        camera.position = [0, 2, -15]
        camera.rotation = [0, 0, 0]
        return camera
    }()
    
    init?(metalKitView: MTKView) {
        Renderer.device = metalKitView.device!
        Renderer.commandQueue = Renderer.device.makeCommandQueue()!
        Renderer.colorPixelFormat = metalKitView.colorPixelFormat
        Renderer.library = Renderer.device.makeDefaultLibrary()
        metalKitView.depthStencilPixelFormat = .depth32Float
        super.init()
        
        buildDepthStencilState()
        
        //creat a sphere
         sphere = Primitive(shape: .sphere, size: 1.0)
        sphere.position = [0,0,0]
        //sphere.pivotPosition = [1,2,0]
        sphere.material.baseColor = [1.0, 0, 0]
        sphere.material.metallic = 0.0
        sphere.material.roughness = 0
        sphere.material.shininess = 0.4
        sphere.material.specularColor = [0,0,0]
        sphere.material.secondColor = [1.0,1.0,0.0]
        sphere.material.ambientOcclusion = [0,0,0]
        sphere.name = "sun"
        
        box = Primitive(shape: .cube, size: 1.0)
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
        
        
    }
    
    func buildDepthStencilState() {
        // 1
        let descriptor = MTLDepthStencilDescriptor()
        // 2
        descriptor.depthCompareFunction = .less
        // 3
        descriptor.isDepthWriteEnabled = true
        depthStencilState =
            Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }

    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        
        
    }
    
    private func updateGameState() {
        /// Update any game state before rendering
        
        
    }
}

extension Renderer : MTKViewDelegate {
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder =
            commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        renderEncoder.setDepthStencilState(depthStencilState)
        
        //fragmentUniforms.cameraPosition = camera.position
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        uniforms.modelMatrix = box.modelMatrix
        uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
        
        
        
        
        renderEncoder.setVertexBuffer(sphere.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        renderEncoder.setRenderPipelineState(box.pipelineState)
        for submesh in box.mesh.submeshes{
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        
       camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
    }
}

