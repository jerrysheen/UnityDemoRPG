Shader "STTools/MipMapViewer"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"
               "RenderPipeline" = "UniversalPipeline"
               "UniversalMaterialType" = "Lit"
               "IgnoreProjector" = "True" }
        
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            float4 _BaseMap_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f input) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_BaseMap, input.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                input.uv *= _BaseMap_TexelSize.z;
                float2  dx_vtc = ddx(input.uv);
                float2  dy_vtc = ddy(input.uv);
                float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
                
                float test =  (0.5 * log2(delta_max_sqr));
                if(test < 0)
                {
                    return half4(1.0, 0.0, 0.0, 1.0f);
                }
                else if(test <= 1.0)
                {
                    return half4(0.0, 1.0, 0.0, 1.0f);
                }
                else
                {
                    return half4(0.0, 0.0, 1.0, 1.0f);
                }


                return col;
            }
            ENDCG
        }
    }
}
