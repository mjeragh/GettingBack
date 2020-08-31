/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import MetalKit

enum Shapes {
    case cube
    case sphere
    case plane
}

class Primitive : Node {
    let vertexBuffer: MTLBuffer
    let mesh: MTKMesh
    let pipelineState: MTLRenderPipelineState
    let debugBoundingBox: DebugBoundingBox
    
    
    
    init(shape: Shapes, size: Float) {
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        
        
        let mdlMesh : MDLMesh!
        switch shape {
        case .cube:
            mdlMesh = MDLMesh(boxWithExtent: [size, size, size],
                              segments: [1, 1, 1],
                              inwardNormals: false, geometryType: .triangles,
                              allocator: allocator)
        case .sphere:
            mdlMesh = MDLMesh(sphereWithExtent: [size, size, size], segments: [100,100], inwardNormals: false, geometryType: .triangles, allocator: allocator)
        case .plane:
            mdlMesh = MDLMesh(planeWithExtent: [size, size, size], segments: [100,100], geometryType: .triangles, allocator: allocator)
        }
        
                // add tangent and bitangent here
                mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed:
                    MDLVertexAttributeTextureCoordinate,
                                        tangentAttributeNamed: MDLVertexAttributeTangent,
                                        bitangentAttributeNamed:
                    MDLVertexAttributeBitangent)
        
        self.mesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
        
        
        self.vertexBuffer = self.mesh.vertexBuffers[0].buffer
        
        
        pipelineState = Primitive.buildPipelineState(vertexDescriptor: mdlMesh.vertexDescriptor)
        debugBoundingBox = DebugBoundingBox(boundingBox: mdlMesh.boundingBox)
        
        super.init()
        self.name = name
        self.nodeGPU.boundingBox.minBounds = mdlMesh.boundingBox.minBounds
        self.nodeGPU.boundingBox.maxBounds = mdlMesh.boundingBox.maxBounds
    }
    
    
    
}
extension Primitive : Renderable {
    func render(renderEncoder: MTLRenderCommandEncoder, uniforms vertex: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
        var uniforms = vertex
        uniforms.modelMatrix = modelMatrix
        uniforms.normalMatrix = modelMatrix.upperLeft
        
        //renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        // render multiple buffers
        // replace the following two lines
        // this only sends the MTLBuffer containing position, normal and UV
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
          renderEncoder.setVertexBuffer(vertexBuffer.buffer,
                                        offset: 0, index: index)
        }
        renderEncoder.setVertexBytes(&uniforms,
                                     length: MemoryLayout<Uniforms>.stride, index: Int(BufferIndexUniforms.rawValue))
        
        
        renderEncoder.setFragmentBytes(&material, length: MemoryLayout<Material>.stride, index: Int(BufferIndexMaterials.rawValue))
       
        var fragmentUniforms = fragment
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        
        renderEncoder.setRenderPipelineState(pipelineState)
        for submesh in mesh.submeshes{
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
        if debugRenderBoundingBox {
          debugBoundingBox.render(renderEncoder: renderEncoder, uniforms: uniforms)
        }
    }
    
    
   private static func makeFunctionConstants()
        -> MTLFunctionConstantValues {
            let functionConstants = MTLFunctionConstantValues()
            var property = false
            functionConstants.setConstantValue(&property, type: .bool, index: 0)
            functionConstants.setConstantValue(&property, type: .bool, index: 1)
            functionConstants.setConstantValue(&property, type: .bool, index: 2)
            
            functionConstants.setConstantValue(&property, type: .bool, index: 3)
            functionConstants.setConstantValue(&property, type: .bool, index: 4)
            functionConstants.setConstantValue(&property, type: .bool, index: 5)
            return functionConstants
    }
    
    private static func buildPipelineState(vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
        let functionConstants = makeFunctionConstants()
        let library = Renderer.library
        
        let vertexFunction = try! library?.makeFunction(name: "vertex_main", constantValues: functionConstants)
        let fragmentFunction: MTLFunction?
        do {
            fragmentFunction = try library?.makeFunction(name: "fragment_main",
                                                         constantValues: functionConstants)
        } catch {
            fatalError("No Metal function exists")
        }
        
        
        
        var pipelineState: MTLRenderPipelineState
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
    
}




