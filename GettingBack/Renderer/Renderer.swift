import MetalKit


class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var colorPixelFormat: MTLPixelFormat!
    static var library: MTLLibrary?
    var depthStencilState: MTLDepthStencilState!
    
    var fragmentUniforms = FragmentUniforms()
    var uniforms = Uniforms()
    let lighting = Lighting()
    
    // Camera holds view and projection matrices
    lazy var camera: Camera = {
        let camera = Camera()
        camera.position = [0, 2, -15]
        camera.rotation = [0, 0, 0]
        return camera
    }()
    
    // Array of Models allows for rendering multiple models
   
    var primitives: [Primitive] = []
   
   
    
    init(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.device = device
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()!
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        Renderer.library = device.makeDefaultLibrary()
        
        super.init()
        metalView.backgroundColor = UIColor.brown
      //  MTLClearColor(red: 0, green: 0, blue: 0.2, alpha: 1)
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        
      
        
        buildDepthStencilState()
        
//
        
        //creat a sphere
        let sphere = Primitive(shape: .sphere, size: 1.0)
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
        primitives.append(sphere)
        
        let box = Primitive(shape: .cube, size: 1.0)
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
        
        
        
        primitives.append(box)
        
        
      
        
      fragmentUniforms.lightCount = lighting.count
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

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder =
            commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        renderEncoder.setDepthStencilState(depthStencilState)
        
       uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        
//
        for primitive in primitives {
            
           uniforms.modelMatrix = primitive.modelMatrix
            uniforms.normalMatrix = primitive.modelMatrix.upperLeft
            
            renderEncoder.setVertexBuffer(primitive.vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&uniforms,
                                         length: MemoryLayout<Uniforms>.stride, index: 1)
            
            var lights = lighting.lights
            renderEncoder.setFragmentBytes(&lights,
                                           length: MemoryLayout<Light>.stride * lights.count,
                                        index: Int(BufferIndexLights.rawValue))
            renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: Int(BufferIndexFragmentUniforms.rawValue))
            renderEncoder.setFragmentBytes(&primitive.material, length: MemoryLayout<Material>.stride, index: Int(BufferIndexMaterials.rawValue))
            renderEncoder.setRenderPipelineState(primitive.pipelineState)
            for submesh in primitive.mesh.submeshes{
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
            }
//    
        }
        
        
       // debugLights(renderEncoder: renderEncoder, lightType: Spotlight)
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}


