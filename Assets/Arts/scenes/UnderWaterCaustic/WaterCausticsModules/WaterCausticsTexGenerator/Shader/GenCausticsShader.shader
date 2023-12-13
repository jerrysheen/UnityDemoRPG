// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

Shader "Hidden/WaterCausticsModules/TexGenShader" {
    Properties { }
    SubShader {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        AlphaToMask Off Cull Off ZWrite Off ZTest Always
        Blend One One
        
        Pass {
            CGPROGRAM

            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex: POSITION;
            };

            struct v2f {
                float4 vertex: SV_POSITION;
                float3 color: TEXCOORD0;
            };

            struct CausticsBufStruct {
                float2 offset;
                float3 color;
            };

            StructuredBuffer<CausticsBufStruct> _BufRefract;

            v2f vert(appdata v) {
                CausticsBufStruct buf = _BufRefract[(uint)v.vertex.z];
                v2f o;

                float3 pos;
                pos.xy = v.vertex.xy + buf.offset;
                pos.z = -1;
                o.vertex = UnityObjectToClipPos(pos);
                o.color = buf.color;
                return o;
            }

            float4 frag(v2f i): SV_Target {
                return i.color.rgbg;
            }
            ENDCG

        }
    }
}
