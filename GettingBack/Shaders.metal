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
    //float2 uv [[ attribute(2)]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
   // float2 uv;
};

[[vertex]] VertexOut vertex_main(const VertexIn vertexIn [[ stage_in ]],
                             constant Uniforms &uniforms [[ buffer(1) ]])
{
    VertexOut out;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix
    * uniforms.modelMatrix * vertexIn.position;
    out.worldPosition = (uniforms.modelMatrix * vertexIn.position).xyz;
    out.worldNormal = uniforms.normalMatrix * vertexIn.normal;
   // out.uv = vertexIn.uv;
    return out;
}

//[[fragment]] float4 fragment_main(VertexOut in [[stage_in]],
//                              constant Light *lights [[buffer(BufferIndexLights)]],
//                              constant Material &material [[ buffer(BufferIndexMaterials) ]], //material is an object
//                              constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms)]]) {
//    float3 baseColor;
//    if (material.gradient == linear){
//        baseColor = mix(material.baseColor, material.secondColor, sqrt(1 - in.uv.y));
//    } else if (material.gradient == radial){
//        //float distanceFromCenter = length(in.uv - float2(0.5,0.5));
//        
//        baseColor = mix(material.baseColor, material.secondColor, in.uv.x + in.uv.y - 2 * in.uv.x * in.uv.y);//distanceFromCenter*2.0);
//    } else { //none
//        baseColor = material.baseColor;
//    }
//    
//    float3 diffuseColor = 0;
//    float3 ambientColor = 0;
//    float3 specularColor = 0;
//    float materialShininess = 32;
//    float3 materialSpecularColor = float3(1, 1, 1);
//    
//    float3 normalDirection = normalize(in.worldNormal);
//    for (uint i = 0; i < fragmentUniforms.lightCount; i++) {
//      Light light = lights[i];
//      if (light.type == Sunlight) {
//        float3 lightDirection = normalize(-light.position);
//        float diffuseIntensity =
//        saturate(-dot(lightDirection, normalDirection));
//        diffuseColor += light.color * baseColor * diffuseIntensity;
//        if (diffuseIntensity > 0) {
//          float3 reflection =
//          reflect(lightDirection, normalDirection);
//          float3 cameraDirection =
//          normalize(in.worldPosition - fragmentUniforms.cameraPosition);
//          float specularIntensity =
//          pow(saturate(-dot(reflection, cameraDirection)),
//              materialShininess);
//          specularColor +=
//          light.specularColor * materialSpecularColor * specularIntensity;
//        }
//      } else if (light.type == Ambientlight) {
//        ambientColor += light.color * light.intensity;
//      } else if (light.type == Pointlight) {
//        float d = distance(light.position, in.worldPosition);
//        float3 lightDirection = normalize(in.worldPosition - light.position);
//        float attenuation = 1.0 / (light.attenuation.x +
//                                   light.attenuation.y * d + light.attenuation.z * d * d);
//        
//        float diffuseIntensity =
//        saturate(-dot(lightDirection, normalDirection));
//        float3 color = light.color * baseColor * diffuseIntensity;
//        color *= attenuation;
//        diffuseColor += color;
//      } else if (light.type == Spotlight) {
//        float d = distance(light.position, in.worldPosition);
//        float3 lightDirection = normalize(in.worldPosition - light.position);
//        float3 coneDirection = normalize(light.coneDirection);
//        float spotResult = dot(lightDirection, coneDirection);
//        if (spotResult > cos(light.coneAngle)) {
//          float attenuation = 1.0 / (light.attenuation.x +
//                                     light.attenuation.y * d + light.attenuation.z * d * d);
//          attenuation *= pow(spotResult, light.coneAttenuation);
//          float diffuseIntensity =
//          saturate(dot(-lightDirection, normalDirection));
//          float3 color = light.color * baseColor * diffuseIntensity;
//          color *= attenuation;
//          diffuseColor += color;
//        }
//      }
//    }
//    float3 color = diffuseColor + ambientColor + specularColor;
//    return float4(color, 1);
//}

[[fragment]] float4 fragment_normals(VertexOut in [[stage_in]]) {
    return float4(in.worldNormal, 1);
    
}
