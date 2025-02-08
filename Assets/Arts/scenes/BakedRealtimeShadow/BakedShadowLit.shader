Shader "Unlit/BakedShadowLit"
{
    // 建筑阴影脚本
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BakedShadowMap ("_BakedShadowMap", 2D) = "white" {}
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD2;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            sampler2D _BakedShadowMap;
            float4 _MainTex_ST;
            
            UNITY_INSTANCING_BUFFER_START(ShadowPros)
                UNITY_DEFINE_INSTANCED_PROP(float4x4, _ShadowMatrix_Array)
                UNITY_DEFINE_INSTANCED_PROP(float4, _ShadowChanelIndex_Array)
            UNITY_INSTANCING_BUFFER_END(ShadowPros)

            #define _ShadowMatrix UNITY_ACCESS_INSTANCED_PROP(ShadowPros, _ShadowMatrix_Array)
            #define _ShadowChanelIndex UNITY_ACCESS_INSTANCED_PROP(ShadowPros, _ShadowChanelIndex_Array)

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 shadowCoord = mul(_ShadowMatrix, float4(i.positionWS, 1.0));
                fixed4 shadowmap = tex2D(_BakedShadowMap, shadowCoord.xy);
                float chanelMixed = dot(shadowmap, _ShadowChanelIndex);

                float shadowattan = 0;
                if(shadowCoord.z > chanelMixed)
                    {shadowattan =  1;}
                else{shadowattan =  0.3f;}
                fixed4 col = tex2D(_MainTex, i.uv);
                return col * shadowattan;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
            }
            ENDCG
        }
    }
}
