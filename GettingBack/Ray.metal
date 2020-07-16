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
    bool accept    [[accept_intersection]]; // Whether to accept or reject the intersection.
    float distance [[distance]];            // Distance from the ray origin to the intersection point.
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
[[intersection(bounding_box)]]
BoundingBoxIntersection IntersectionFunction(// Ray parameters passed to the ray intersector below
                                             float3 origin               [[origin]],
                                             float3 direction            [[direction]],
                                             float minDistance           [[min_distance]],
                                             float maxDistance           [[max_distance]],
                                             // Information about the primitive.
                                             unsigned int primitiveIndex [[primitive_id]]
                                             )
{
    
    
    // Check for intersection between the ray and sphere mathematically.
    float3 oc = origin ;//- sphere.origin;
    
    float a = dot(direction, direction);
    float b = 2 * dot(oc, direction);
    float c = dot(oc, oc);// - sphere.radius * sphere.radius;
    
    float disc = b * b - 4 * a * c;
    
    BoundingBoxIntersection ret;
    
    if (disc <= 0.0f) {
        // If the ray missed the sphere, return false.
        ret.accept = false;
    }
    else {
        // Otherwise, compute the intersection distance.
        ret.distance = (-b - sqrt(disc)) / (2 * a);
        
        // The intersection function must also check whether the intersection distance is
        // within the acceptable range. Intersection functions do not run in any particular order,
        // so the maximum distance may be different from the one passed into the ray intersector.
        ret.accept = ret.distance >= minDistance && ret.distance <= maxDistance;
    }
    
    return ret;
}

// Main ray tracing kernel.
kernel void raytracingKernel(uint2 tid [[thread_position_in_grid]],
                             constant Uniforms & uniforms,
                             
                             primitive_acceleration_structure accelerationStructure
                             )
{
    // The sample aligns the thread count to the threadgroup size. which means the thread count
    // may be different than the bounds of the texture. Test to make sure this thread
    // is referencing a pixel within the bounds of the texture.
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        // The ray to cast.
        ray ray;
        
        // Pixel coordinates for this thread.
        float2 pixel = (float2)tid;
        
        
        // Map pixel coordinates to -1..1.
        float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
        uv = uv * 2.0f - 1.0f;
        
        //constant Camera & camera = uniforms.camera;
        
        // Rays start at the camera position.
        ray.origin = uniforms.origin;
        
        // Map normalized pixel coordinates into camera's coordinate system.
        ray.direction = uniforms.direction;//normalize(uv.x * uniforms.right + uv.y * uniforms.up + uniforms.forward);
        
        // Don't limit intersection distance.
        ray.max_distance = INFINITY;
        
        
        // Create an intersector to test for intersection between the ray and the geometry in the scene.
        intersector<> i;
        
        
        typename intersector<>::result_type intersection;
        
        
        // Get the closest intersection, not the first intersection. This is the default, but
        // the sample adjusts this property below when it casts shadow rays.
        i.accept_any_intersection(false);
        
        // Check for intersection between the ray and the acceleration structure. If the sample
        // isn't using intersection functions, it doesn't need to include one.
        intersection = i.intersect(ray, accelerationStructure);
        
        // Stop if the ray didn't hit anything and has bounced out of the scene.
        if (intersection.type == intersection_type::none)
        {
            
        }else {
            // Look up the mask for this instance, which indicates what type of geometry the ray hit.
            unsigned int mask = instances[instanceIndex].mask;
            
            
            
            // The ray hit something. Look up the transformation matrix for this instance.
            float4x4 objectToWorldSpaceTransform(1.0f);
            
            for (int column = 0; column < 4; column++)
                for (int row = 0; row < 3; row++)
                    objectToWorldSpaceTransform[column][row] = instances[instanceIndex].transformationMatrix[column][row];
            
            // Compute intersection point in world space.
            float3 worldSpaceIntersectionPoint = ray.origin + ray.direction * intersection.distance;
            
            unsigned primitiveIndex = intersection.primitive_id;
            
            float2 barycentric_coords = intersection.triangle_barycentric_coord;
        }
        
        
    }
}
