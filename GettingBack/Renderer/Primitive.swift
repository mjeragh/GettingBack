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
    //let debugBoundingBox: DebugBoundingBox
    
    
    
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
        
        //        // add tangent and bitangent here
        //        mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed:
        //            MDLVertexAttributeTextureCoordinate,
        //                                tangentAttributeNamed: MDLVertexAttributeTangent,
        //                                bitangentAttributeNamed:
        //            MDLVertexAttributeBitangent)
        
        self.mesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
        
        
        self.vertexBuffer = self.mesh.vertexBuffers[0].buffer
        
        
        pipelineState = Primitive.buildPipelineState(vertexDescriptor: mdlMesh.vertexDescriptor)
        //debugBoundingBox = DebugBoundingBox(boundingBox: mdlMesh.boundingBox)
        
        super.init()
        self.name = name
        self.boundingBox = mdlMesh.boundingBox
    }
    
    
    
}
extension Primitive : Renderable {
    func render(renderEncoder: MTLRenderCommandEncoder, uniforms vertex: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
        var uniforms = vertex
        uniforms.modelMatrix = modelMatrix
        uniforms.normalMatrix = modelMatrix.upperLeft
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms,
                                     length: MemoryLayout<Uniforms>.stride, index: 1)
        
        
        renderEncoder.setFragmentBytes(&material, length: MemoryLayout<Material>.stride, index: Int(BufferIndexMaterials.rawValue))
        renderEncoder.setRenderPipelineState(pipelineState)
        for submesh in mesh.submeshes{
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
        
    }
    
    private static func buildPipelineState(vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
        let library = Renderer.library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
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


