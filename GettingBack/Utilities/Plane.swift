//
//  File.swift
//  HitTestMetal
//
//  Created by Mohammad Jeragh on 4/10/19.
//  Copyright © 2019 Mohammad Jeragh. All rights reserved.
//

import Foundation
import simd
import os.log
import MetalKit

struct Plane {
    let n: SIMD4<Float>
    var a : Float {
      return n.x
    }
    var  b: Float {
        return n.y
    }
    var c: Float {
    return n.z
    }
    var d: Float {
    return n.w
    }
    //the (a, b, c, d) in a*x + b*y + c*z + d = 0.
    
    var debugPlane: Primitive?
    
    init(a: Float, b: Float, c: Float, d: Float, debug: Bool = false )
    {
        self.n = SIMD4<Float>(a, b, c, d)
        if debug {
            self.debugPlane = Primitive(shape: .plane, size: 20)
            //debugPlane?.rotation = [c * radians(fromDegrees: -90), a * radians(fromDegrees: -90), b * radians(fromDegrees: -90)]
            debugPlane?.rotation = [a,c,b]
            debugPlane?.position = [a,c + d,b]
            debugPlane?.material.baseColor = [0, 0.1, 0.1]//[0, 0.0, 0]
            debugPlane?.material.metallic = 1.0 //0.0
            debugPlane?.material.roughness = 0.0 //0.1
            debugPlane?.material.shininess = 0.1 //1.0
            debugPlane?.material.specularColor = [0,1.0,0.0]//[0,0.0,0.0]
            debugPlane?.material.ambientOcclusion = [1.0,1.0,1.0]
            
            
            
            debugPlane?.name = "debugPlane"
        }
    }
    
    /// the equations are from this site
   /// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection
   
    
    func intersectionPlane(_ ray: LocalRay) -> Float {
        let n = normalize(SIMD3<Float>(self.n.xyz))
        os_log("n: %f %f %f",n.x,n.y,n.z)
        let pZero = SIMD3<Float>(0,0 + d,0)
        let denom = -simd_dot(n, ray.localDirection)
        os_log("p0: %f, %f, %f, denom: %f", pZero.x,pZero.y,pZero.z,denom)
        if (abs(denom) > Float(1e-6)){ //the abs I added to fix the issue of under the plane
            let p0l0 = ray.localOrigin - pZero
            let t = simd_dot(p0l0, n) / denom
            os_log("t: %f",t)
            return t
        }
        
        
        return Float(0.0)
    }
    
    
    
}
