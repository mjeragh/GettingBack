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

constant bool hasColorTexture [[function_constant(0)]];
constant bool hasNormalTexture [[function_constant(1)]];
constant bool hasSkeleton [[function_constant(5)]];


struct VertexIn {
  float4 position [[attribute(Position)]];
  float3 normal [[attribute(Normal)]];
  float2 uv [[attribute(UV)]];
  float3 tangent [[attribute(Tangent)]];
  float3 bitangent [[attribute(Bitangent)]];
    ushort4 joints [[attribute(Joints)]];
    float4 weights [[attribute(Weights)]];
};



struct VertexOut {
  float4 position [[position]];
  float3 worldPosition;
  float3 worldNormal;
  float3 worldTangent;
  float3 worldBitangent;
  float2 uv;
};


[[vertex]] VertexOut vertex_main(const VertexIn vertexIn [[stage_in]],
                                 constant float4x4 *jointMatrices [[buffer(22), function_constant(hasSkeleton)]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    float4 position = vertexIn.position;
    float4 normal = float4(vertexIn.normal,0);
    float4 tangent = float4(vertexIn.tangent,0);
    float4 bitangent = float4(vertexIn.bitangent,0);
    
    if (hasSkeleton){
        float4 weights = vertexIn.weights;
        ushort4 joints = vertexIn.joints;
        position=
            weights.x * (jointMatrices[joints.x] * position) +
            weights.y * (jointMatrices[joints.y] * position) +
            weights.z * (jointMatrices[joints.z] * position) +
            weights.w * (jointMatrices[joints.w] * position);
        normal=
            weights.x * (jointMatrices[joints.x] * normal) +
            weights.y * (jointMatrices[joints.y] * normal) +
            weights.z * (jointMatrices[joints.z] * normal) +
            weights.w * (jointMatrices[joints.w] * normal);
        tangent=
            weights.x * (jointMatrices[joints.x] * tangent) +
            weights.y * (jointMatrices[joints.y] * tangent) +
            weights.z * (jointMatrices[joints.z] * tangent) +
            weights.w * (jointMatrices[joints.w] * tangent);
        bitangent=
            weights.x * (jointMatrices[joints.x] * bitangent) +
            weights.y * (jointMatrices[joints.y] * bitangent) +
            weights.z * (jointMatrices[joints.z] * bitangent) +
            weights.w * (jointMatrices[joints.w] * bitangent);
    }
    
  VertexOut out {
    .position = uniforms.projectionMatrix * uniforms.viewMatrix
    * uniforms.modelMatrix * position,
    .worldPosition = (uniforms.modelMatrix * vertexIn.position).xyz,
    .worldNormal = uniforms.normalMatrix * normal.xyz,
    .worldTangent = uniforms.normalMatrix * tangent.xyz,
    .worldBitangent = uniforms.normalMatrix * bitangent.xyz,
    .uv = vertexIn.uv
  };
  return out;
}

[[fragment]] float4 fragment_main(VertexOut in [[stage_in]],
                              constant Light *lights [[buffer(BufferIndexLights)]],
                              constant Material &material [[ buffer(BufferIndexMaterials) ]], //material is an object
                              constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms)]]) {
    float3 baseColor;
    if (material.gradient == linear){
        baseColor = mix(material.baseColor, material.secondColor, sqrt(1 - in.uv.y));
    } else if (material.gradient == radial){
        //float distanceFromCenter = length(in.uv - float2(0.5,0.5));

        baseColor = mix(material.baseColor, material.secondColor, in.uv.x + in.uv.y - 2 * in.uv.x * in.uv.y);//distanceFromCenter*2.0);
    } else { //none
        baseColor = material.baseColor;
    }

    float3 diffuseColor = 0;
    float3 ambientColor = 0;
    float3 specularColor = 0;
    float materialShininess = 32;
    float3 materialSpecularColor = float3(1, 1, 1);

    float3 normalDirection = normalize(in.worldNormal);
    for (uint i = 0; i < fragmentUniforms.lightCount; i++) {
      Light light = lights[i];
      if (light.type == Sunlight) {
        float3 lightDirection = normalize(-light.position);
        float diffuseIntensity =
        saturate(-dot(lightDirection, normalDirection));
        diffuseColor += light.color * baseColor * diffuseIntensity;
        if (diffuseIntensity > 0) {
          float3 reflection =
          reflect(lightDirection, normalDirection);
          float3 cameraDirection =
          normalize(in.worldPosition - fragmentUniforms.cameraPosition);
          float specularIntensity =
          pow(saturate(-dot(reflection, cameraDirection)),
              materialShininess);
          specularColor +=
          light.specularColor * materialSpecularColor * specularIntensity;
        }
      } else if (light.type == Ambientlight) {
        ambientColor += light.color * light.intensity;
      } else if (light.type == Pointlight) {
        float d = distance(light.position, in.worldPosition);
        float3 lightDirection = normalize(in.worldPosition - light.position);
        float attenuation = 1.0 / (light.attenuation.x +
                                   light.attenuation.y * d + light.attenuation.z * d * d);

        float diffuseIntensity =
        saturate(-dot(lightDirection, normalDirection));
        float3 color = light.color * baseColor * diffuseIntensity;
        color *= attenuation;
        diffuseColor += color;
      } else if (light.type == Spotlight) {
        float d = distance(light.position, in.worldPosition);
        float3 lightDirection = normalize(in.worldPosition - light.position);
        float3 coneDirection = normalize(light.coneDirection);
        float spotResult = dot(lightDirection, coneDirection);
        if (spotResult > cos(light.coneAngle)) {
          float attenuation = 1.0 / (light.attenuation.x +
                                     light.attenuation.y * d + light.attenuation.z * d * d);
          attenuation *= pow(spotResult, light.coneAttenuation);
          float diffuseIntensity =
          saturate(dot(-lightDirection, normalDirection));
          float3 color = light.color * baseColor * diffuseIntensity;
          color *= attenuation;
          diffuseColor += color;
        }
      }
    }
    float3 color = diffuseColor + ambientColor + specularColor;
    return float4(color, 1);
}
//
//[[fragment]] float4 fragment_normals(VertexOut in [[stage_in]]) {
//    return float4(in.worldNormal, 1);
//
//}
