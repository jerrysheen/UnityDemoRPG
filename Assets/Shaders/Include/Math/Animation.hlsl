#ifndef Animation_Insancing
#define Animation_Insancing

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


uniform sampler2D _SkinningTex;
//TEXTURE2D(_SkinningTex);   SAMPLER(sampler_SkinningTex);

CBUFFER_START(UnityPerMaterial)
float _CurFramIndex;
float _PreFramIndex;
float _TransProgress;
float4 _SkinningTexSize;
CBUFFER_END

#ifdef UNITY_DOTS_INSTANCING_ENABLED
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
        UNITY_DOTS_INSTANCED_PROP(float, _CurFramIndex)
        UNITY_DOTS_INSTANCED_PROP(float, _PreFramIndex)
        UNITY_DOTS_INSTANCED_PROP(float, _TransProgress)
        UNITY_DOTS_INSTANCED_PROP(float4, _SkinningTexSize)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        #define _CurFramIndex UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata__CurFramIndex)
        #define _PreFramIndex UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata__PreFramIndex)
        #define _TransProgress UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata__TransProgress)
        #define _SkinningTexSize UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4, Metadata__SkinningTexSize)
#endif

#define _SkinningTexW _SkinningTexSize.x
#define _SkinningTexH _SkinningTexSize.y



    inline float4 getUV(float startIndex){
        float y=(int)(startIndex/_SkinningTexSize);
        float u=(startIndex-y*_SkinningTexSize)/_SkinningTexSize;
        float v=y/_SkinningTexSize;
        return float4(u,v,0,0);
    }
    
    inline float4x4 getMatrix(float startIndex){
        float4 row0=tex2Dlod(_SkinningTex,getUV(startIndex));
        float4 row1=tex2Dlod(_SkinningTex,getUV(startIndex+1));
        float4 row2=tex2Dlod(_SkinningTex,getUV(startIndex+2));
        return float4x4(row0,row1,row2,float4(0,0,0,1));
    }

    
    inline float4 Skin(float4 bone,float4 weight,float4 vn)
    {

        const float _curFramIndex = _CurFramIndex;
        const float _preFramIndex = _PreFramIndex;
        const float _progess = _TransProgress;


        float4x4 curmatrix1=getMatrix(_curFramIndex+bone.x*3);
        float4x4 curmatrix2=getMatrix(_curFramIndex+bone.y*3);
        float4x4 curmatrix3=getMatrix(_curFramIndex+bone.z*3);
        float4x4 curmatrix4=getMatrix(_curFramIndex+bone.w*3);

        float4x4 prematrix1=getMatrix(_preFramIndex+bone.x*3);
        float4x4 prematrix2=getMatrix(_preFramIndex+bone.y*3);
        float4x4 prematrix3=getMatrix(_preFramIndex+bone.z*3);
        float4x4 prematrix4=getMatrix(_preFramIndex+bone.w*3);

        float4 curPos=mul(curmatrix1,vn)*weight.x;
        curPos=curPos+mul(curmatrix2,vn)*weight.y;
        curPos=curPos+mul(curmatrix3,vn)*weight.z;
        curPos=curPos+mul(curmatrix4,vn)*weight.w;

        
        float4 prePos=mul(prematrix1,vn)*weight.x;
        prePos=prePos+mul(prematrix2,vn)*weight.y;
        prePos=prePos+mul(prematrix3,vn)*weight.z;
        prePos=prePos+mul(prematrix4,vn)*weight.w;

        return lerp(curPos,prePos,_progess);

    }

#endif