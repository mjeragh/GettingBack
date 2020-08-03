
import MetalKit

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  static var colorPixelFormat: MTLPixelFormat!
  static var fps: Int!

 // static var fragmentUniforms = FragmentUniforms()
  let depthStencilState: MTLDepthStencilState
//  let lighting = Lighting()
  var scene: Scene?
  
  init(metalView: MTKView) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Renderer.device = device
    Renderer.commandQueue = commandQueue
    Renderer.library = device.makeDefaultLibrary()
    Renderer.colorPixelFormat = metalView.colorPixelFormat
    Renderer.fps = metalView.preferredFramesPerSecond
    
    metalView.device = device
    metalView.depthStencilPixelFormat = .depth32Float
    
    depthStencilState = Renderer.buildDepthStencilState()!
    super.init()
    metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0,
                                         blue: 0.1, alpha: 1)

    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)

  }
  

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return
      Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }
  
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    scene?.sceneSizeWillChange(to: size)
  }
  
  func draw(in view: MTKView) {
    guard
      let scene = scene,
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        return
    }
    
    // update all the models' poses
    let deltaTime = 1 / Float(Renderer.fps)
    scene.update(deltaTime: deltaTime)

    
    renderEncoder.setDepthStencilState(depthStencilState)

    var lights = scene.lighting.lights
    renderEncoder.setFragmentBytes(&lights,
                                   length: MemoryLayout<Light>.stride * lights.count,
                                   index: Int(BufferIndexLights.rawValue))
//    renderEncoder.setFragmentBytes(&scene.fragmentUniforms,
//                                   length: MemoryLayout<FragmentUniforms>.stride,
//                                   index: Int(BufferIndexFragmentUniforms.rawValue))

    // render all the models in the array
    for renderable in scene.renderables {
      renderEncoder.pushDebugGroup(renderable.name)
      renderable.render(renderEncoder: renderEncoder,
                        uniforms: scene.uniforms,
                        fragmentUniforms: scene.fragmentUniforms)
      renderEncoder.popDebugGroup()
    }
    
    //debug
    if let debug = scene.touchPlane.debugPlane{
        renderEncoder.pushDebugGroup(debug.name)
        debug.render(renderEncoder: renderEncoder,
                          uniforms: scene.uniforms,
                          fragmentUniforms: scene.fragmentUniforms)
        renderEncoder.popDebugGroup()
    }
//    renderEncoder.pushDebugGroup("SunLight")
//    scene.debugLights(renderEncoder: renderEncoder, lightType: Sunlight)
//    renderEncoder.popDebugGroup()
//    renderEncoder.pushDebugGroup("AmbientLight")
//    scene.debugLights(renderEncoder: renderEncoder, lightType: Pointlight)
//    renderEncoder.popDebugGroup()
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}
