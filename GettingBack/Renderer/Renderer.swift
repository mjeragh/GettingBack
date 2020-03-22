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
//    var colorMap: MTLTexture
    
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
        
        
        }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        
       camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
    }
}

