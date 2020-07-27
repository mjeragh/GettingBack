//
//  Ray.metal
//  GettingBack
//
//  Created by Mohammad Jeragh on 7/12/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
using namespace raytracing;

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"


// Return type for a bounding box intersection function.
struct BoundingBoxIntersection {
    bool accept   ; // Whether to accept or reject the intersection.
    float4 distance ;            // Distance from the ray origin to the intersection point.
};


/*
 Custom sphere intersection function. The [[intersection]] keyword marks this as an intersection
 function. The [[bounding_box]] keyword means that this intersection function handles intersecting rays
 with bounding box primitives. To create sphere primitives, the sample creates bounding boxes that
 enclose the sphere primitives.
 
 The [[triangle_data]] and [[instancing]] keywords indicate that the intersector that calls this
 intersection function returns barycentric coordinates for triangle intersections and traverses
 an instance acceleration structure. These keywords must match between the intersection functions,
 intersection function table, intersector, and intersection result to ensure that Metal propagates
 data correctly between stages. Using fewer tags when possible may result in better performance,
 as Metal may need to store less data and pass less data between stages. For example, if you do not
 need barycentric coordinates, omitting [[triangle_data]] means Metal can avoid computing and storing
 them.
 
 The arguments to the intersection function contain information about the ray, primitive to be
 tested, and so on. The ray intersector provides this datas when it calls the intersection function.
 Metal provides other built-in arguments but this sample doesn't use them.
 */
BoundingBoxIntersection IntersectionFunction(BoundingBox boundingBox,
                                             ray ray
                                             )
{
    
    
    float3 tmin = boundingBox.minBounds;
    float3 tmax = boundingBox.maxBounds;
    
    float3 inverseDirection = 1 / ray.direction;
    
    int sign[3];
    sign[0]= (inverseDirection.x < 0);
    sign[1]= (inverseDirection.y < 0);
    sign[2]= (inverseDirection.z < 0);
    
    BoundingBoxIntersection ret;
    ret.accept = false;
    
    float3 bounds[2] = {tmin,tmax};
    
    tmin.x = (bounds[sign[0]].x - ray.origin.x) * inverseDirection.x;
    tmax.x = (bounds[1 - sign[0]].x - ray.origin.x) * inverseDirection.x;
    
    tmin.y = (bounds[sign[1]].y - ray.origin.y) * inverseDirection.y;
    tmax.y = (bounds[1 - sign[1]].y - ray.origin.y) * inverseDirection.y;
    
    float t0 = float(tmax.z);
    
    if ((tmin.x > tmax.y) || (tmin.y > tmax.x)){
        
        return ret;
    }
    
    
    
    if (tmin.y > tmin.x){
        tmin.x = tmin.y;
    }
    
    
    if (tmax.y < tmax.x){
        tmax.x = tmax.y;
    }
    
    tmin.z = (bounds[sign[2]].z - ray.origin.z) * inverseDirection.z;
    tmax.z = (bounds[1-sign[2]].z - ray.origin.z) * inverseDirection.z;
    
    
    
    if ((tmin.x > tmax.z) || (tmin.z > tmax.x)){
        
        return ret;
    }
    
    if (tmin.z > tmin.x){
        tmin.x = tmin.z;
        t0 = tmin.x;
    }
    
    if (tmax.z < tmax.x){
        tmax.x = tmax.z;
        t0 = tmax.x;
    }
    
    ret.accept = true;
    ret.distance =float4(ray.origin + ray.direction * t0, 1);
    return ret ;
}
 

float interpolate(ray r, float3 p){
    return length(p - float3(0,0,0)) / length(r.direction);
}

kernel void testKernel(constant Uniforms & uniforms [[buffer(1)]],
                       
                       device NodeGPU *nodeGPU [[buffer(0)]],
                       uint pid [[thread_position_in_grid]]){
    
    BoundingBoxIntersection answer;
    ray ray;
    ray.origin = nodeGPU[pid].localRay.localOrigin;
    
    // Map normalized pixel coordinates into camera's coordinate system.
    ray.direction = nodeGPU[pid].localRay.localDirection;//normalize(uv.x * uniforms.right + uv.y * uniforms.up + uniforms.forward);
    
    // Don't limit intersection distance.
    ray.max_distance = INFINITY;
   //intersector is not supported by anything lower than A13, not iOS14
   //I will move my intersector from CPU to the GPU
    
    //hit test with local ray
    
    answer = IntersectionFunction(nodeGPU[pid].boundingBox, ray);
    nodeGPU[pid].debug = 1;
    nodeGPU[pid].parameter = INFINITY;//10000000000.0;
    if (answer.accept){
        
        float3 worldPoint = (nodeGPU[pid].modelMatrix * answer.distance).xyz;
        struct ray worldRay;
        worldRay.origin = uniforms.origin;
        worldRay.direction = uniforms.direction;
        nodeGPU[pid].debug = 2;
        nodeGPU[pid].parameter = interpolate(worldRay, worldPoint);
        
    }
    
}


// Main ray tracing kernel.
/// Trying to figure it out

