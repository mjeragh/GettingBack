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
    var position: SIMD3<Float> = [0, 0, 0]
    var rotation: float3 = [0, 0, 0] {
      didSet {
        let rotationMatrix = float4x4(rotation: rotation)
        quaternion = simd_quatf(rotationMatrix)
      }
    }
    var quaternion = simd_quatf()
    var scale: SIMD3<Float> = [1, 1, 1]
    var test: SIMD4<Float> = [1,1,1,1] //I cant remember why I need this Test
    weak var parent: Node?
    var material = Material()
    var children: [Node] = []
    var nodeGPU = NodeGPU()
    

    var boundingBox = MDLAxisAlignedBoundingBox()
    var size: SIMD3<Float> {
        return boundingBox.maxBounds - boundingBox.minBounds
    }
    
   // var boundingSphere = BoundingSphere(center: SIMD3<Float>(0,0,0), radius: 0, debugBoundingSphere: nil)
    
  
  var modelMatrix: float4x4 {
    let translateMatrix = float4x4(translation: position)
    let rotateMatrix = float4x4(rotation: rotation)
    let scaleMatrix = float4x4(scaling: scale)
    return translateMatrix * rotateMatrix * scaleMatrix
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
        //TODO: The following code is redudant, I will take care of it later
        childNode.nodeGPU.boundingBox.minBounds = childNode.boundingBox.minBounds
        childNode.nodeGPU.boundingBox.maxBounds = childNode.boundingBox.maxBounds
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

//    func unproject(_ ray: Ray) -> HitResult?{
//        let modelToWorld = worldTransform//float4x4.identity()
//        let localRay = modelToWorld.inverse * ray
//
//        var nearest: HitResult?
//        if let modelPoint = boundingBox.intersect(localRay) {
//            let worldPoint = modelToWorld * modelPoint
//            let worldParameter = ray.interpolate(worldPoint)
//            nearest = HitResult(node: self, ray: ray, parameter: worldParameter)
//        }
//
//
//        return nearest
//    }
//
//    func hitTest(_ ray: Ray) -> HitResult? {
//        let modelToWorld = worldTransform
//        let localRay = modelToWorld.inverse * ray
//
//        var nearest: HitResult?
//        if let modelPoint = boundingBox.intersect(localRay) {
//            let worldPoint = modelToWorld * modelPoint
//            let worldParameter = ray.interpolate(worldPoint)
//            nearest = HitResult(node: self, ray: ray, parameter: worldParameter)
//        }
//
//        var nearestChildHit: HitResult?
//        for child in children {
//            if (child.name == "plane") {continue}
//            if let childHit = child.hitTest(ray) {
//                if let nearestActualChildHit = nearestChildHit {
//                    if childHit < nearestActualChildHit {
//                        nearestChildHit = childHit
//                    }
//                } else {
//                    nearestChildHit = childHit
//                }
//            }
//        }
//
//        if let nearestActualChildHit = nearestChildHit {
//            if let nearestActual = nearest {
//                if nearestActualChildHit < nearestActual {
//                    return nearestActualChildHit
//                }
//            } else {
//                return nearestActualChildHit
//            }
//        }
//
//        return nearest
//    }

    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    var debugDescription: String { return "<Node>: \(name )" }
}
//
//extension MDLAxisAlignedBoundingBox {
//
//    func intersect(_ ray: Ray) -> SIMD4<Float>? {
//
//        var tmin = minBounds
//        var tmax = maxBounds
//
//        let inverseDirection = 1 / ray.direction
//
//        let sign : [Int] = [(inverseDirection.x < 0) ? 1 : 0,(inverseDirection.y < 0) ? 1 : 0,(inverseDirection.z < 0) ? 1 : 0]
//
//
//        let bounds : [SIMD3<Float>] = [tmin,tmax]
//
//        tmin.x = (bounds[sign[0]].x - ray.origin.x) * inverseDirection.x
//        tmax.x = (bounds[1 - sign[0]].x - ray.origin.x) * inverseDirection.x
//
//        tmin.y = (bounds[sign[1]].y - ray.origin.y) * inverseDirection.y
//        tmax.y = (bounds[1 - sign[1]].y - ray.origin.y) * inverseDirection.y
//
//        var t0 = Float(tmax.z)
//
//        if ((tmin.x > tmax.y) || (tmin.y > tmax.x)){
//            os_log("first nil")
//            return nil
//        }
//
//
//
//        if (tmin.y > tmin.x){
//            tmin.x = tmin.y;
//        }
//
//
//        if (tmax.y < tmax.x){
//            tmax.x = tmax.y;
//        }
//
//        tmin.z = (bounds[sign[2]].z - ray.origin.z) * inverseDirection.z
//        tmax.z = (bounds[1-sign[2]].z - ray.origin.z) * inverseDirection.z
//
//
//
//        if ((tmin.x > tmax.z) || (tmin.z > tmax.x)){
//            os_log("second nil")
//            return nil
//        }
//
//        if (tmin.z > tmin.x){
//            tmin.x = tmin.z
//            t0 = tmin.x
//        }
//
//        if (tmax.z < tmax.x){
//            tmax.x = tmax.z
//            t0 = tmax.x
//        }
//
//        print("t0 \(t0)")
//        return SIMD4<Float>(ray.origin + ray.direction * t0, 1)
//    }
//}
