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

struct VertexIn {
    float4 position [[ attribute(0) ]];
    float3 normal [[ attribute(1) ]];
    float2 uv [[ attribute(2)]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[ stage_in ]],
                             constant Uniforms &uniforms [[ buffer(1) ]])
{
    VertexOut out;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix
    * uniforms.modelMatrix * vertexIn.position;
    out.worldPosition = (uniforms.modelMatrix * vertexIn.position).xyz;
    out.worldNormal = uniforms.normalMatrix * vertexIn.normal;
    out.uv = vertexIn.uv;
    return out;
}

fragment float4 fragment_normals(VertexOut in [[stage_in]]) {
    return float4(in.worldNormal, 1);
    
}
