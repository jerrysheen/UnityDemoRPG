#ifndef UNIVERSAL_TERRAIN_LIT_PASS_INCLUDED
#define UNIVERSAL_TERRAIN_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "./TerrainInput.hlsl"

struct Attributes
{
    float4 positionOS    : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float2 texcoord      : TEXCOORD0;
};

struct Varyings
{
    float4 tSpace0 : NORMAL;
    float4 tSpace1 : TANGENT;
    float4 tSpace2 : COLOR;
    float4 texUVID : TEXCOORD0;
    float4 posOS : TEXCOORD2;
    float4 vertex : SV_POSITION;
};

#ifdef _RVT_BAKE
struct PixelOutput
{
    float4 col0 : COLOR0;
    float4 col1 : COLOR1;
};

float4x4 _ImageMVP;
float4 _BlendTile;
#endif

#ifdef _RVT_RENDER
float4 _VTFeedbackParam;
float4 _VTPageParam;
float4 _VTTileParam;
float4 _VTRealRect;
TEXTURE2D(_VTLookupTex); SAMPLER(sampler_VTLookupTex);
TEXTURE2D(_VTDiffuse); SAMPLER(sampler_VTDiffuse);
TEXTURE2D(_VTNormal); SAMPLER(sampler_VTNormal);
#endif

///////////////////////////////////////////////////////////////////////////////
//                  Function                                                 //
///////////////////////////////////////////////////////////////////////////////
// https://www.iquilezles.org/www/articles/texturerepetition/texturerepetition.htm
// Technique 3
struct NoTileFactors
{
    float2 uva;
    float2 uvb;
    float2 ddx;
    float2 ddy;
    float f;
};

void calcNoTileFactors(in float2 uv, out NoTileFactors outFactors)
{
    // sample variation pattern    
    float k = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, 0.005*uv ).x; // cheap (cache friendly) lookup    
    
    // compute index    
    float index = k*8.0;
    float i = floor( index );
    outFactors.f = frac( index );

    // offsets for the different virtual patterns    
    outFactors.uva = uv + sin(float2(3.0,7.0)*(i+0.0)); // can replace with any other hash    
    outFactors.uvb = uv + sin(float2(3.0,7.0)*(i+1.0)); // can replace with any other hash    

    // compute derivatives for mip-mapping    
    outFactors.ddx = ddx(uv);
    outFactors.ddy = ddy(uv);
}

float4 tex2DNoTile(in float index, in NoTileFactors factors)
{
	float4 color0 = SAMPLE_TEXTURE2D_ARRAY_GRAD(_DiffuseArr, sampler_DiffuseArr, factors.uva, index, factors.ddx, factors.ddy);
	float4 color1 = SAMPLE_TEXTURE2D_ARRAY_GRAD(_DiffuseArr, sampler_DiffuseArr, factors.uvb, index, factors.ddx, factors.ddy);
	
	return lerp(color0, color1, smoothstep(0.2, 0.8, factors.f - 0.1 * dot((color0-color1).rgb, float3(1,1,1))));
}

// stochastic texturing
// https://drive.google.com/file/d/1QecekuuyWgw68HU9tg6ENfrCTCVIjm6l/view
struct StochasticFactors
{
    float2 rand0;
    float2 rand1;
    float2 rand2;
    float3 weight;
    float2 ddx;
    float2 ddy;
};

void calcStochasticFactors(in float2 uv, out StochasticFactors outFactors)
{
    //skew the uv to create triangular grid
    float2 skewUV = mul(float2x2 (1.0, 0.0, -0.57735027, 1.15470054), uv * 3.464);

    //vertices on the triangular grid
    int2 vertID = int2(floor(skewUV));

    //barycentric coordinates of uv position
    float3 temp = float3(frac(skewUV), 0);
    temp.z = 1.0 - temp.x - temp.y;
	    
    //each vertex on the grid gets an according weight value
    int2 vert0, vert1, vert2;
    float cmp0 = step(temp.z, 0);
    float cmp1 = step(0, temp.z);
    float sig = sign(temp.z);
    outFactors.weight = float3(sig * temp.z, cmp0 + sig * temp.y, cmp0 + sig * temp.x);
    vert0 = vertID + cmp0 * int2(1, 1);
    vert1 = vertID + int2(cmp0, cmp1);
    vert2 = vertID + int2(cmp1, cmp0);

    //get derivatives to avoid triangular artifacts
    outFactors.ddx = ddx(uv);
    outFactors.ddy = ddy(uv);

    //offset uvs using magic numbers
    outFactors.rand0 = uv + frac(sin(fmod(float2(dot(vert0, float2(127.1, 311.7)), dot(vert0, float2(269.5, 183.3))), 3.14159)) * 43758.5453);
    outFactors.rand1 = uv + frac(sin(fmod(float2(dot(vert1, float2(127.1, 311.7)), dot(vert1, float2(269.5, 183.3))), 3.14159)) * 43758.5453);
    outFactors.rand2 = uv + frac(sin(fmod(float2(dot(vert2, float2(127.1, 311.7)), dot(vert2, float2(269.5, 183.3))), 3.14159)) * 43758.5453);
}

float4 tex2DStochastic(in float index, in StochasticFactors factors)
{
    //get texture samples
    float4 sample0 = SAMPLE_TEXTURE2D_ARRAY_GRAD(_DiffuseArr, sampler_DiffuseArr, factors.rand0, index, factors.ddx, factors.ddy);
    float4 sample1 = SAMPLE_TEXTURE2D_ARRAY_GRAD(_DiffuseArr, sampler_DiffuseArr, factors.rand1, index, factors.ddx, factors.ddy);
    float4 sample2 = SAMPLE_TEXTURE2D_ARRAY_GRAD(_DiffuseArr, sampler_DiffuseArr, factors.rand2, index, factors.ddx, factors.ddy);
	    
    //blend samples with weights	
    return sample0 * factors.weight.x + sample1 * factors.weight.y + sample2 * factors.weight.z;
}

float getNormalmapWeight(in uint index)
{
    return _NormalChoiceArray[index / 4][index % 4];
}

// Precision-adjusted variations of https://www.shadertoy.com/view/4djSRW
float hash(float p) { p = frac(p * 0.011); p *= p + 7.5; p *= p + p; return frac(p); }
float hash(float2 p) {float3 p3 = frac(float3(p.xyx) * 0.13); p3 += dot(p3, p3.yzx + 3.333); return frac((p3.x + p3.y) * p3.z); }

float noise(float x) {
    float i = floor(x);
    float f = frac(x);
    float u = f * f * (3.0 - 2.0 * f);
    return lerp(hash(i), hash(i + 1.0), u);
}


float noise(float2 x) {
    float2 i = floor(x);
    float2 f = frac(x);

    // Four corners in 2D of a tile
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    // Simple 2D lerp using smoothstep envelope between the values.
    // return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
    //			mix(c, d, smoothstep(0.0, 1.0, f.x)),
    //			smoothstep(0.0, 1.0, f.y)));

    // Same code, with the clamps in smoothstep and common subexpressions
    // optimized away.
    float2 u = f * f * (3.0 - 2.0 * f);
    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

inline half OneMinusReflectivityFromMetallic ( half metallic )
{
    half oneMinusDielectricSpec = half4 ( 0.04 , 0.04 , 0.04 , 1.0 - 0.04 ) . a ;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec ;
}

inline half3 DiffuseAndSpecularFromMetallic ( half3 albedo , half metallic , out half3 specColor , out half oneMinusReflectivity )
{
    specColor = lerp ( half4 ( 0.04 , 0.04 , 0.04 , 1.0 - 0.04 ) . rgb , albedo , metallic ) ;
    oneMinusReflectivity = OneMinusReflectivityFromMetallic ( metallic ) ;
    return albedo * oneMinusReflectivity ;
}

float SmoothnessToPerceptualRoughness ( float smoothness )
{
    return ( 1 - smoothness ) ;
}

half4 BRDF2_Unity_PBS ( half3 diffColor , half3 specColor , half oneMinusReflectivity , half smoothness ,float3 normal , float3 viewDir)
{
    Light mainLight = GetMainLight();
    const float3 lightDir = mainLight.direction.xyz;
    float3 halfDir = SafeNormalize ( lightDir + viewDir ) ;

    half nl = saturate ( dot ( normal , lightDir ) ) ;
    float nh = saturate ( dot ( normal , halfDir ) ) ;
    half nv = saturate ( dot ( normal , viewDir ) ) ;
    float lh = saturate ( dot ( lightDir , halfDir ) ) ;

    half perceptualRoughness = SmoothnessToPerceptualRoughness ( smoothness ) ;
    half roughness = PerceptualRoughnessToRoughness ( perceptualRoughness ) ;
 
    float a = roughness ;
    float a2 = a * a ;

    float d = nh * nh * ( a2 - 1.f ) + 1.00001f ;
    float specularTerm = a2 / ( max ( 0.1f , lh * lh ) * ( roughness + 0.5f ) * ( d * d ) * 4 ) ;
    half surfaceReduction = ( 0.6 - 0.08 * perceptualRoughness ) ;
    surfaceReduction = 1.0 - roughness * perceptualRoughness * surfaceReduction ;

    half grazingTerm = saturate ( smoothness + ( 1 - oneMinusReflectivity ) ) ;
    half3 color = ( diffColor + specularTerm * specColor ) * mainLight.color * nl;

    return half4 ( color , 1 ) ;
}

inline half4 LightingStandard(float3 normal, float3 viewDir, half3 albedo, half metallic, half smoothness)
{
    half oneMinusReflectivity ;
    half3 specColor ;
    albedo = DiffuseAndSpecularFromMetallic (albedo , metallic, specColor , oneMinusReflectivity) ;
    return BRDF2_Unity_PBS(albedo, specColor, oneMinusReflectivity, smoothness, normal, viewDir);
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Simple Lighting) shader
Varyings TerrainPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;
#ifdef _RVT_BAKE
    output.vertex = mul(_ImageMVP, input.positionOS);
#else
    output.vertex = TransformObjectToHClip(input.positionOS.xyz);
#endif
    output.texUVID.xy = input.texcoord;
    float3 wpos = TransformObjectToWorld(input.positionOS.xyz).xyz;
    output.posOS = input.positionOS;

    float3 worldNormal = TransformObjectToWorldNormal(input.normal);
    float3 worldTangent = TransformObjectToWorldDir(input.tangent.xyz);
    float tangentSign = input.tangent.w * unity_WorldTransformParams.w;
    float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
    output.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, wpos.x);
    output.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, wpos.y);
    output.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, wpos.z);

    return output;
}

// Used for StandardSimpleLighting shader
#ifdef _RVT_BAKE
PixelOutput TerrainPassFragment(Varyings input) : SV_Target
#else
half4 TerrainPassFragment(Varyings input) : SV_Target
#endif
{

    const float3 wpos = float3(input.tSpace0.w, input.tSpace1.w, input.tSpace2.w);
    float2 globalBlendUV = float2((wpos.x - _Rect.x) / _Rect.z, (wpos.z - _Rect.y) / _Rect.w);

    float2 diffuseUV = TRANSFORM_TEX(wpos.xz, _DiffuseArr);
    float2 _ddx, _ddy;

    #if _IDFORMAT_R8G8
    float4 globalBlendFactor = SAMPLE_TEXTURE2D(_IDMapTex,sampler_IDMapTex, globalBlendUV);
    float4 globalBlendFactorBA = globalBlendFactor.zwzw;    
    uint4 indexMap = uint4(uint(round(globalBlendFactor.r * 255.0)) >> 4, uint(round(globalBlendFactor.r * 255.0)) & 15, uint(round(globalBlendFactor.g * 255.0)) >> 4, uint(round(globalBlendFactor.g * 255.0)) & 15);
    #elif _IDFORMAT_R8
    float4 globalBlendFactor = float4(SAMPLE_TEXTURE2D(_IDMapTex, sampler_IDMapTex, globalBlendUV).r, 
                                                        SAMPLE_TEXTURE2D(_IDMapTex, sampler_IDMapTex, globalBlendUV - float2(_IDMapTex_TexelSize.x, 0)).r,
                                                        SAMPLE_TEXTURE2D(_IDMapTex, sampler_IDMapTex, globalBlendUV - _IDMapTex_TexelSize.xy).r,
                                                        SAMPLE_TEXTURE2D(_IDMapTex, sampler_IDMapTex, globalBlendUV - float2(0, _IDMapTex_TexelSize.y)).r);

    uint4 indexMap = uint4(uint(round(globalBlendFactor.r * 255.0))& 15, uint(round(globalBlendFactor.g * 255.0))& 15, uint(round(globalBlendFactor.a * 255.0))& 15, uint(round(globalBlendFactor.b * 255.0))& 15);
    float4 globalBlendFactorBA = SAMPLE_TEXTURE2D(_IDMapTex,sampler_IDMapTex, globalBlendUV).zwzw;;   
    #endif
    half globalBlendWeight = saturate(_WorldSpaceCameraPos.y / _BlendDistanceFactor);
    half localBlendWeight = 1.0 - globalBlendWeight;

    half4 color0 = SAMPLE_TEXTURE2D_ARRAY_LOD(_DiffuseArr, sampler_DiffuseArr, diffuseUV, indexMap.x, 0);

    half4 color1 = color0;
        color1 = SAMPLE_TEXTURE2D_ARRAY_LOD(_DiffuseArr, sampler_DiffuseArr, diffuseUV, indexMap.y, 0);

    half4 color2 = color0;
        color2 = SAMPLE_TEXTURE2D_ARRAY_LOD(_DiffuseArr, sampler_DiffuseArr, diffuseUV, indexMap.z, 0);

    half4 color3 = color0;
        color3 = SAMPLE_TEXTURE2D_ARRAY_LOD(_DiffuseArr, sampler_DiffuseArr, diffuseUV, indexMap.w, 0);

    half4 diffuseBlend;
    float2 pixelPos = (globalBlendUV) * _IDMapTex_TexelSize.zw;
    float2 biWeight = frac(pixelPos);

    diffuseBlend = lerp(lerp(color3, color2, biWeight.x), lerp(color1, color0, biWeight.x), biWeight.y);
    return diffuseBlend;
}

#ifdef _RVT_RENDER
half4 VTTerrainPassFragment(Varyings input) : SV_Target
{
    const float3 wpos = float3(input.tSpace0.w, input.tSpace1.w, input.tSpace2.w);
    //const float3 wpos = TransformObjectToWorld(input.posOS.xyz).xyz;
    float2 uv = (wpos.xz - _VTRealRect.xy) / _VTRealRect.zw;
    float2 uvInt = uv - frac(uv * _VTPageParam.x) * _VTPageParam.y;
    float4 page = round(SAMPLE_TEXTURE2D(_VTLookupTex, sampler_VTLookupTex, uvInt) * 255.0);
#ifdef _SHOWRVTMIPMAP
    return float4(clamp(1 - page.b * 0.1, 0, 1), 0, 0, 1);
#endif
    float2 inPageOffset = frac(uv * exp2(_VTPageParam.z - page.b));
    uv = (page.rg * (_VTTileParam.y + _VTTileParam.x * 2) + inPageOffset * _VTTileParam.y + _VTTileParam.x) / _VTTileParam.zw;
    half3 albedo = SAMPLE_TEXTURE2D(_VTDiffuse, sampler_VTDiffuse, uv);
    float3 normalTS = /*UnpackNormal*/(SAMPLE_TEXTURE2D(_VTNormal, sampler_VTNormal, uv));
    const float3 viewDirWS = normalize(_WorldSpaceCameraPos - wpos);

    float3 worldNormal = float3(dot(input.tSpace0.xyz, normalTS.xyz),
        dot(input.tSpace1.xyz, normalTS.xyz),
        dot(input.tSpace2.xyz, normalTS.xyz));
    worldNormal = normalize(worldNormal);

    //return float4(albedo, 1.0f);
    return LightingStandard(worldNormal, viewDirWS, albedo, _Metallic, _Glossiness);
}
#endif

#endif
