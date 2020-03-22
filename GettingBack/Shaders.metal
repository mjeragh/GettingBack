//
//  Shaders.metal
//  GettingBack
//
//  Created by Mohammad Jeragh on 3/12/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float3 normal   [[attribute(VertexAttributeNormal)]];
    
} Vertex;

typedef struct
{
    float4 position [[position]];
    
} VertexOut;

vertex VertexOut vertexShader(Vertex in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    VertexOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
   

    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]]
                             )
{
    
    return float4(1,0,0,0);
}
