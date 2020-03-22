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
    float4 position [[attribute(VertexAttributePosition)]];
    float3 normal   [[attribute(VertexAttributeNormal)]];
    
} Vertex;

typedef struct
{
    float4 position [[position]];
    float3 normal;
} VertexOut;

vertex VertexOut vertex_main(Vertex in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    VertexOut out;

    out.position = uniforms.projectionMatrix * uniforms.viewMatrix *  uniforms.modelMatrix * in.position;
   out.normal = uniforms.normalMatrix * in.normal;

    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]])
{
    
    return float4(in.normal,1);
}
