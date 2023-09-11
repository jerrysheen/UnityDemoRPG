// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Animation/diff" {
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
		//	Name "FORWARD"
		//	Tags { "LightMode" = "ForwardBase" }

			Cull Off
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Animation.cginc"
			uniform sampler2D _MainTex;
			uniform fixed4 _LightColor0;

			struct VertexInput{
				float4 vertex:POSITION;
				float4 normal:NORMAL;
				float2 uv:TEXCOORD0;
				float4 uv1:TEXCOORD2;
				float4 uv2:TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput{
				float4 vertex:SV_POSITION;
				float3 normal:NORMAL;
				float2 uv:TEXCOORD0;
			};

			VertexOutput vert(VertexInput input){
				VertexOutput output;
				
				float4 vert=Skin(input.uv1,input.uv2,input.vertex);
				float4 normal=Skin(input.uv1,input.uv2,input.normal);

				output.vertex=UnityObjectToClipPos(vert);
				output.normal=UnityObjectToWorldNormal(normal);
				output.uv=input.uv;
				return output;
			}

			float4 frag(VertexOutput output):COLOR{

				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed diff = max (0, dot (output.normal,worldLightDir));

				float4 col=tex2D(_MainTex,output.uv);
				float rgb=step(dot(output.normal,_WorldSpaceLightPos0.xyz),0);
				col.rgb+=UNITY_LIGHTMODEL_AMBIENT.rgb;//*(_LightColor0.rgb-rgb)+rgb;
				return col*diff*_LightColor0 ;
			}
			ENDCG
		}

		//Pass {
		//	Name "ShadowCaster"
		//	Tags { "LightMode" = "ShadowCaster" }

		//	CGPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag
		//	#pragma target 2.0
		//	#pragma multi_compile_shadowcaster
		//	#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
		//	#include "UnityCG.cginc"
		//	#include "Animation.cginc"


		//	struct VertexInput
		//	{
		//		float4 vertex:POSITION;
		//		float4 normal:NORMAL;
		//		float2 uv:TEXCOORD0;
		//		float4 uv1:TEXCOORD2;
		//		float4 uv2:TEXCOORD3;
		//		UNITY_VERTEX_INPUT_INSTANCE_ID
		//	};


		//	struct v2f {
		//		V2F_SHADOW_CASTER;
		//		UNITY_VERTEX_OUTPUT_STEREO
		//	};

		//	v2f vert( VertexInput v )
		//	{
		//		v2f o;
		//		UNITY_SETUP_INSTANCE_ID(v);
		//		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		//		v.vertex=Skin(v.uv1,v.uv2,v.vertex);
		//		v.normal=Skin(v.uv1,v.uv2,v.normal);
		//		TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
		//		return o;
		//	}

		//	float4 frag( v2f i ) : SV_Target
		//	{
		//		SHADOW_CASTER_FRAGMENT(i)
		//	}
		//	ENDCG

		//}
	}
}
