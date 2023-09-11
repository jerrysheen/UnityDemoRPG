Shader "Animation/LambertDQ(gray)" {
	Properties{
		//_MainColor("_MainColor",color) = (1,1,1,1)
		_Hue("Hue", Range(0,359)) = 0
		_Saturation("Saturation", Range(0,3.0)) = 1.0
		_Luminance("_Luminance", Range(0,3.0)) = 1.0


		_DissolveColor("_DissolveColor",color) = (1,1,1,1)
		_Edge("EdgeWide",range(0,1)) = 0.5
		_Dissolve("Dissolve",range(-1,1)) = -1
		_MaskTex("ColorMask",2D) = "white"{}

		_MainTex("MainTex",2D) = "white"{}

		_MatCap("MatCap",2D) = "black"{}
		_MatCapChannel("_MatCapChannel",2D) = "black"{}

		_SkinningTex("SkinningTex",2D) = "black"{}
		_SkinningTexW("SkinningTexW",Float) = 0
		_SkinningTexH("SkinningTexH",Float) = 0
	}
	SubShader{
		Tags{
			"RenderType" = "Opaque"
		}
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" "Queue" = "Transparent" }
			Cull Off
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "AnimationDQ.cginc"
			#include "HSV.cginc"
			#include "MatCap.cginc"
			//#pragma multi_compile _ LOD_FADE_CROSSFADE

			struct VertexInput {
				float4 vertex:POSITION;
				float4 normal:NORMAL;
				float2 uv:TEXCOORD0;
				float4 uv1:TEXCOORD3;
				float4 uv2:TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput {
				float4 vertex:SV_POSITION;
				float3 normal:NORMAL;
				float2 uv:TEXCOORD0;
				float2 matcap:TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			UNITY_INSTANCING_BUFFER_START(Colors)
			UNITY_DEFINE_INSTANCED_PROP(float, _Dissolve)
			UNITY_DEFINE_INSTANCED_PROP(float, _Gray)
			UNITY_DEFINE_INSTANCED_PROP(float, _Hue)
			UNITY_DEFINE_INSTANCED_PROP(float, _Saturation)
			UNITY_DEFINE_INSTANCED_PROP(float, _Luminance)
			UNITY_DEFINE_INSTANCED_PROP(float4, _DissolveColor)


			UNITY_INSTANCING_BUFFER_END(Colors)



			uniform fixed4 _LightColor0;
			uniform sampler2D _MainTex, _MaskTex, _MatCap, _MatCapChannel;
			float4 _MainTex_ST;

			float _Edge;
			//	float4 _DissolveColor;

			//	float _Saturation, _Luminance, _Hue;

			
			VertexOutput vert(VertexInput input) {
				VertexOutput output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				float4 vert = SkinDQ(input.uv1,input.uv2,input.vertex);
				float4 normal = SkinDQ(input.uv1,input.uv2,input.normal);
				output.vertex = UnityObjectToClipPos(vert);
				output.normal = UnityObjectToWorldNormal(normal);
				output.uv = input.uv;
				output.matcap=MatCapUV(input.normal);
				return output;
			}

			float4 frag(VertexOutput i) :COLOR{
				UNITY_SETUP_INSTANCE_ID(i);
				float g = UNITY_ACCESS_INSTANCED_PROP(Colors, _Gray);
				float dissolve = UNITY_ACCESS_INSTANCED_PROP(Colors, _Dissolve);

				float Hue = UNITY_ACCESS_INSTANCED_PROP(Colors, _Hue);
				float Saturation = UNITY_ACCESS_INSTANCED_PROP(Colors, _Saturation);

				float Luminance = UNITY_ACCESS_INSTANCED_PROP(Colors, _Luminance);
				float3 dissolveColor = UNITY_ACCESS_INSTANCED_PROP(Colors, _DissolveColor);





				float4 col = tex2D(_MainTex,i.uv);
				float3 mask = tex2D(_MaskTex, i.uv);

				float3 hsv;

				//hsv = (col.xyz);
				hsv.xyz = RGBConvertToHSV(col.xyz);
				hsv.x += Hue; 
				hsv.x = hsv.x % 360;
				hsv.y *= Saturation;
				hsv.z *= Luminance;
				hsv = HSVConvertToRGB(hsv.xyz);
				col.xyz = hsv* mask.r + col.xyz* (1 - mask.r);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//UNITY_APPLY_DITHER_CROSSFADE(i.vertex)
				fixed diff = max(0, dot(i.normal, worldLightDir));

				float c1 = mask.b + dissolve;
				float c2 = c1 - (dissolve + _Edge);
				float3 color = lerp(0,dissolveColor, max(0,c1 - (c2 - c1)));
				col.rgb += color * 10;
				if (c1 > 0.2)
				{
					discard;
				}


				float3 channel = tex2D(_MatCapChannel, i.uv).rgb;

				float2 matUV = i.matcap.xy * 0.5;
				float2 materialUV = matUV + (float2(channel.g, channel.r) + float2(channel.b, channel.b)) * 0.5;

				float3 matcap = SamplerMatCap(_MatCap, matUV);
				float3 material= SamplerMatCap(_MatCap, materialUV);
				col.rgb += material;
				col.rgb += matcap;

				//col.rgb *= diff+ UNITY_LIGHTMODEL_AMBIENT;
				



				return col;
			}
			ENDCG
		}
		UsePass "Hidden/PlaneShadow/0"
		// Pass
		// {
			// 	Name "ShadowCaster"
			// 	Tags { "LightMode" = "ShadowCaster" }
			// 	CGPROGRAM
			// 	#pragma vertex vert
			// 	#pragma fragment frag
			// 	#pragma target 2.0
			// 	#pragma multi_compile_shadowcaster
			// 	#pragma multi_compile_instancing 
			// 	#include "UnityCG.cginc"
			// 	#include "AnimationDQ.cginc"


			// 	struct VertexInput
			// 	{
				// 		float4 vertex:POSITION;
				// 		float4 normal:NORMAL;
				// 		float2 uv:TEXCOORD0;
				// 		float4 uv1:TEXCOORD3;
				// 		float4 uv2:TEXCOORD4;
				// 		UNITY_VERTEX_INPUT_INSTANCE_ID
			// 	};


			// 	struct v2f {
				// 		V2F_SHADOW_CASTER;
				// 		UNITY_VERTEX_OUTPUT_STEREO
			// 	};

			// 	v2f vert(VertexInput v)
			// 	{
				// 		v2f o;
				// 		UNITY_SETUP_INSTANCE_ID(v);
				// 		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				// 		v.vertex = SkinDQ(v.uv1, v.uv2, v.vertex);
				// 		TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				// 		return o;
			// 	}

			// 	float4 frag(v2f i) : SV_Target
			// 	{
				// 		SHADOW_CASTER_FRAGMENT(i)
			// 	}
			// 	ENDCG

		// }
	}
}
