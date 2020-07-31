//
/**
 * Copyright (c) 2019 Razeware LLC
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

class Model: Node {
  
  let meshes: [Mesh]
  var tiling: UInt32 = 1
  let samplerState: MTLSamplerState?
  static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor

  init(name: String) {
    guard
      let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
        fatalError("Model: \(name) not found")
    }
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(url: assetUrl,
                         vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                         bufferAllocator: allocator)
    
    // load Model I/O textures
    asset.loadTextures()
    
    var mtkMeshes: [MTKMesh] = []
    let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
    _ = mdlMeshes.map { mdlMesh in
      mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed:
        MDLVertexAttributeTextureCoordinate,
                              tangentAttributeNamed: MDLVertexAttributeTangent,
                              bitangentAttributeNamed: MDLVertexAttributeBitangent)
      Model.vertexDescriptor = mdlMesh.vertexDescriptor
      mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
    }

    meshes = zip(mdlMeshes, mtkMeshes).map {
      Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
    }
    samplerState = Model.buildSamplerState()
    super.init()
    self.name = name
    self.nodeGPU.boundingBox.minBounds = asset.boundingBox.minBounds
    self.nodeGPU.boundingBox.maxBounds = asset.boundingBox.maxBounds
  }
  
  private static func buildSamplerState() -> MTLSamplerState? {
    let descriptor = MTLSamplerDescriptor()
    descriptor.sAddressMode = .repeat
    descriptor.tAddressMode = .repeat
    descriptor.mipFilter = .linear
    descriptor.maxAnisotropy = 8
    let samplerState =
      Renderer.device.makeSamplerState(descriptor: descriptor)
    return samplerState
  }
}





extension Model : Renderable {
    func render(renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
        // add tiling here
        var fragmentUniforms = fragment
        fragmentUniforms.tiling = tiling
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        var uniforms = uniforms
        
        uniforms.modelMatrix = modelMatrix
        uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
        
        renderEncoder.setVertexBytes(&uniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))
        
        for mesh in meshes {

          // render multiple buffers
          // replace the following two lines
          // this only sends the MTLBuffer containing position, normal and UV
          for (index, vertexBuffer) in mesh.mtkMesh.vertexBuffers.enumerated() {
            renderEncoder.setVertexBuffer(vertexBuffer.buffer,
                                          offset: 0, index: index)
          }
          
            for submesh in mesh.submeshes {
              renderEncoder.setRenderPipelineState(submesh.pipelineState)
              // textures
              renderEncoder.setFragmentTexture(submesh.textures.baseColor,
                                               index: Int(BaseColorTexture.rawValue))
              renderEncoder.setFragmentTexture(submesh.textures.normal,
                                               index: Int(NormalTexture.rawValue))
              renderEncoder.setFragmentTexture(submesh.textures.roughness,
                                               index: Int(RoughnessTexture.rawValue))
              renderEncoder.setFragmentTexture(submesh.textures.metallic,
                                               index: Int(MetallicTexture.rawValue))
              renderEncoder.setFragmentTexture(submesh.textures.ao,
                                               index: Int(AOTexture.rawValue))

              // set the materials here
              var material = submesh.material
              renderEncoder.setFragmentBytes(&material,
                                             length: MemoryLayout<Material>.stride,
                                             index: Int(BufferIndexMaterials.rawValue))

              let mtkSubmesh = submesh.mtkSubmesh
              renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                  indexCount: mtkSubmesh.indexCount,
                                                  indexType: mtkSubmesh.indexType,
                                                  indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                                  indexBufferOffset: mtkSubmesh.indexBuffer.offset)
            }
        }
      }
    
    
}

