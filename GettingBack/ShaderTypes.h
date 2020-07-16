//
//  ShaderTypes.h
//  GettingBack
//
//  Created by Mohammad Jeragh on 3/12/20.
//  Copyright © 2020 Mohammad Jeragh. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
    unsigned int width;
    unsigned int height;
    //camera
    vector_float3 origin;
    vector_float3 direction;
    vector_float3 up;
    vector_float3 right;
    vector_float3 forward;
} Uniforms;

typedef struct {
  uint lightCount;
  vector_float3 cameraPosition;
  uint tiling;
} FragmentUniforms;

typedef enum {
    unused = 0,
    Sunlight = 1,
    Spotlight = 2,
    Pointlight = 3,
    Ambientlight = 4
} LightType;

typedef struct {
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    float intensity;
    vector_float3 attenuation;
    LightType type;
    float coneAngle;
    vector_float3 coneDirection;
    float coneAttenuation;
} Light;

typedef enum {
    none = 0,
    linear = 1,
    radial = 2
} Gradient;

typedef struct {
    vector_float3 baseColor;
    vector_float3 secondColor;
    vector_float3 specularColor;
    float roughness;
    float metallic;
    vector_float3 ambientOcclusion;
    float shininess;
    vector_float4 irradiatedColor;
    Gradient gradient;
} Material;

typedef enum {
  BufferIndexVertices = 0,
  BufferIndexUniforms = 11,
  BufferIndexLights = 12,
  BufferIndexFragmentUniforms = 13,
  BufferIndexMaterials = 14
} BufferIndices;

typedef enum {
  Position = 0,
  Normal = 1,
  UV = 2,
  Tangent = 3,
  Bitangent = 4,
  Color = 5,
  Joints = 6,
  Weights = 7
} Attributes;

#endif /* ShaderTypes_h */

