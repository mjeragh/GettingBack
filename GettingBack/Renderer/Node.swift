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
import os.log


class Node {
    let identifier = UUID()
    var name: String = "untitled"
    var nodeGPU = NodeGPU()
    var position: SIMD3<Float> = [0, 0, 0]{
        didSet {
            let translateMatrix = float4x4(translation: position)
            let rotateMatrix = float4x4(rotation: rotation)
            let scaleMatrix = float4x4(scaling: scale)
             
            nodeGPU.modelMatrix = translateMatrix * rotateMatrix * scaleMatrix
        }
    }
    var rotation: float3 = [0, 0, 0] {
      didSet {
        let rotationMatrix = float4x4(rotation: rotation)
        quaternion = simd_quatf(rotationMatrix)
        let translateMatrix = float4x4(translation: position)
        let scaleMatrix = float4x4(scaling: scale)
         
        nodeGPU.modelMatrix = translateMatrix * rotationMatrix * scaleMatrix
      }
    }
    var quaternion = simd_quatf()
    var scale: SIMD3<Float> = [1, 1, 1]{
        didSet {
            let translateMatrix = float4x4(translation: position)
            let rotateMatrix = float4x4(rotation: rotation)
            let scaleMatrix = float4x4(scaling: scale)
             
            nodeGPU.modelMatrix = translateMatrix * rotateMatrix * scaleMatrix
        }
    }
    var test: SIMD4<Float> = [1,1,1,1] //I cant remember why I need this Test
    weak var parent: Node?
    var material = Material()
    var children: [Node] = []
    
    

//    var boundingBox = MDLAxisAlignedBoundingBox()
    var size: SIMD3<Float> {
        return nodeGPU.boundingBox.maxBounds - nodeGPU.boundingBox.minBounds
    }
    
   // var boundingSphere = BoundingSphere(center: SIMD3<Float>(0,0,0), radius: 0, debugBoundingSphere: nil)
    
        
  var modelMatrix: float4x4 {
    let translateMatrix = float4x4(translation: position)
    let rotateMatrix = float4x4(rotation: rotation)
    let scaleMatrix = float4x4(scaling: scale)
    nodeGPU.modelMatrix = translateMatrix * rotateMatrix * scaleMatrix
    return nodeGPU.modelMatrix
  }
  
    var worldTransform: float4x4 {
        if let parent = parent {
            return parent.worldTransform * modelMatrix
        } else {
            return modelMatrix
        }
    }
    
   
    
    func update(deltaTime: Float) {
      // override this
    }
    
    final func add(childNode: Node) {
      children.append(childNode)
      childNode.parent = self
      childNode.nodeGPU.debug = 0
    }
    
    final func remove(childNode: Node) {
      for child in childNode.children {
        child.parent = self
        children.append(child)
      }
      childNode.children = []
      guard let index = (children.firstIndex {
        $0 === childNode
      }) else { return }
      children.remove(at: index)
      childNode.parent = nil
    }
    
    func removeFromParent() {
        parent?.remove(childNode: self)
    }
    
    var forwardVector: float3 {
      return normalize([sin(rotation.y), 0, cos(rotation.y)])
    }
    
    var rightVector: float3 {
      return [forwardVector.z, forwardVector.y, -forwardVector.x]
    }
    
}

extension Node: Equatable, CustomDebugStringConvertible {


    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    var debugDescription: String { return "<Node>: \(name )" }
}

