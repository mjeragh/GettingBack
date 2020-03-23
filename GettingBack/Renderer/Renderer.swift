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


class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var colorPixelFormat: MTLPixelFormat!
    static var library: MTLLibrary?

    var depthStencilState: MTLDepthStencilState!
    var uniforms = Uniforms()
    var sphere, box : Primitive!
    
    // Camera holds view and projection matrices
    lazy var camera: Camera = {
        let camera = Camera()
        camera.position = [0, 2, -15]
        camera.rotation = [0, 0, 0]
        return camera
    }()
    
    init(metalKitView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.device = device
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()!
        Renderer.colorPixelFormat = metalKitView.colorPixelFormat
        Renderer.library = device.makeDefaultLibrary()
        
        super.init()
        metalKitView.clearColor = MTLClearColor(red: 0, green: 0,
                                             blue: 0.2, alpha: 1)
        metalKitView.delegate = self
        mtkView(metalKitView, drawableSizeWillChange: metalKitView.bounds.size)
        
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
        uniforms.modelMatrix = sphere.modelMatrix
        uniforms.normalMatrix = float3x3(normalFrom4x4: sphere.modelMatrix)
        
        
        
        
        renderEncoder.setVertexBuffer(sphere.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        renderEncoder.setRenderPipelineState(sphere.pipelineState)
        for submesh in sphere.mesh.submeshes{
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

