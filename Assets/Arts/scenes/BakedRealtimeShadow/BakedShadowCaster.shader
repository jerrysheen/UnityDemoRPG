Shader "Unlit/BakedShadowCaster"
{
    Properties
    {
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
            };

            struct v2f
            {
                float3 positionWS : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _BakedShadowMap;
            uniform float4x4 _ShadowMatrix;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                    //half cascadeIndex = ComputeCascadeUniqueIndex(positionWS);
                float4 shadowCoord = mul(_ShadowMatrix, float4(i.positionWS, 1.0));
                shadowCoord.x = (shadowCoord.x + shadowCoord.w) * 0.5;
                shadowCoord.y = (shadowCoord.y + shadowCoord.w) * 0.5;
                shadowCoord.z = (shadowCoord.z + shadowCoord.w) * 0.5;

                shadowCoord = shadowCoord / max(shadowCoord.w,0.001);
                //float4 shadowCoord = mul(_ShadowMatrix, float4(i.positionWS, 1.0));
                fixed4 shadowmap = tex2D(_BakedShadowMap, shadowCoord.xy);
                half result = step(0.1f, shadowmap.r);
                return result;
            }
            ENDCG
        }
    }
}
