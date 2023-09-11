Shader "Animation/DQLambert" {
	Properties{
		_MainTex("MainTex",2D)="white"{}
		_SkinningTex("SkinningTex",2D)="black"{}
		_SkinningTexSize("SkinningTexSize",Float)=0
	}
	SubShader{
		Tags{
			"RenderType"="Opaque"
		}
		Pass{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Cull Off
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Animation.cginc"

			struct VertexInput{
				float4 vertex:POSITION;
				float4 normal:NORMAL;
				float2 uv:TEXCOORD0;
				float4 uv1:TEXCOORD3;
				float4 uv2:TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput{
				float4 vertex:SV_POSITION;
				float3 normal:NORMAL;
				float2 uv:TEXCOORD0;
			};
			uniform fixed4 _LightColor0;
			uniform sampler2D _MainTex;
			
			VertexOutput vert(VertexInput input){
				VertexOutput output;
				UNITY_SETUP_INSTANCE_ID(input);
				float4 vert=Skin(input.uv1,input.uv2,input.vertex);
				float4 normal=Skin(input.uv1,input.uv2,input.normal);
				output.vertex=UnityObjectToClipPos(vert);
				output.normal=UnityObjectToWorldNormal(normal);
				output.uv=input.uv;
				return output;
			}

			float4 frag(VertexOutput i):COLOR{
				float4 col=tex2D(_MainTex,i.uv);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 diff = _LightColor0.rgb*max (0, dot (normalize(i.normal), worldLightDir))+UNITY_LIGHTMODEL_AMBIENT.rgb;
				col.rgb *= diff;
				return col;
			}
			ENDCG
		}


		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing 
			#include "UnityCG.cginc"
			#include "Animation.cginc"


			struct VertexInput
			{
				float4 vertex:POSITION;
				float4 normal:NORMAL;
				float2 uv:TEXCOORD0;
				float4 uv1:TEXCOORD3;
				float4 uv2:TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};


			struct v2f {
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert( VertexInput v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				v.vertex=Skin(v.uv1,v.uv2,v.vertex);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag( v2f i ) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG

		}
	}
}
