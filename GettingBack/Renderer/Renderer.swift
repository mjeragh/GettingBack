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
//    var depthState: MTLDepthStencilState
//    var colorMap: MTLTexture
    
    
    
    init?(metalKitView: MTKView) {
        Renderer.device = metalKitView.device!
        Renderer.commandQueue = Renderer.device.makeCommandQueue()!
     
        
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
        
//        let aspect = Float(size.width) / Float(size.height)
//        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65), aspectRatio:aspect, nearZ: 0.1, farZ: 100.0)
    }
}

