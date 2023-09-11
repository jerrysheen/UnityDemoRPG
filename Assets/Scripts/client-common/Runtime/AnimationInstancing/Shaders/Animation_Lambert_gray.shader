Shader "Animation/Lambert(gray)" {
	Properties{
		//_Gray("_Gray",float)=1
		_DissolveColor("_DissolveColor",color) = (1,1,1,1)
		_Edge("EdgeWide",range(0,1)) = 0.5
		_Dissolve("Dissolve",range(-1,1)) = -1
		_MainTex("MainTex",2D) = "white"{}
		_MaskTex("MaskTex",2D) = "white"{}
		_SkinningTex("SkinningTex",2D) = "black"{}
		_SkinningTexSize("SkinningTexSize",Float) = 0

	}
		SubShader{
			Tags{"RenderType" = "Opaque"}
			Pass{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#include "UnityCG.cginc"
				#include "Animation.cginc"
				#pragma multi_compile _ LOD_FADE_CROSSFADE
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
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				UNITY_INSTANCING_BUFFER_START(Colors)
					UNITY_DEFINE_INSTANCED_PROP(float, _Dissolve)
					UNITY_DEFINE_INSTANCED_PROP(float, _Gray)
				UNITY_INSTANCING_BUFFER_END(Colors)



				uniform fixed4 _LightColor0;
				uniform sampler2D _MainTex, _MaskTex;
				float4 _MainTex_ST;

				float _Edge;
				float4 _DissolveColor;

				VertexOutput vert(VertexInput input) {
					VertexOutput output;
					UNITY_SETUP_INSTANCE_ID(input);
					UNITY_TRANSFER_INSTANCE_ID(input, output);
					float4 vert = Skin(input.uv1,input.uv2,input.vertex);
					float4 normal = Skin(input.uv1,input.uv2,input.normal);
					output.vertex = UnityObjectToClipPos(vert);
					output.normal = UnityObjectToWorldNormal(normal);
					output.uv = input.uv;
					return output;
				}

				float4 frag(VertexOutput i) :COLOR{
					UNITY_SETUP_INSTANCE_ID(i);
					float g = UNITY_ACCESS_INSTANCED_PROP(Colors, _Gray);
					float dissolve=UNITY_ACCESS_INSTANCED_PROP(Colors, _Dissolve);

					float4 col = tex2D(_MainTex,i.uv);
					float3 mask = tex2D(_MaskTex, i.uv);
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//	fixed3 diff = _LightColor0.rgb * max(0, dot(normalize(i.normal), worldLightDir)) + UNITY_LIGHTMODEL_AMBIENT.rgb;
					UNITY_APPLY_DITHER_CROSSFADE(output.vertex)
					//col.rgb *= diff;
					float gray = dot(col.rgb, fixed3(0.22, 0.707, 0.071));
					col.rgb = lerp(col.rgb,float3(gray, gray, gray), clamp(g,0,1));
					float c1 = mask.b +dissolve;
					float c2 = c1 - (dissolve + _Edge);
					//float3 color = dissolve *step(0.18,c1);
					float3 color = _DissolveColor  * max(0,c1 - (c2 - c1));
					col.rgb += color*10 ;
					if (c1 > 0.2)
					{
						discard;
					}
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

				v2f vert(VertexInput v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					v.vertex = Skin(v.uv1,v.uv2,v.vertex);
					TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					SHADOW_CASTER_FRAGMENT(i)
				}
				ENDCG

			}
		}
}
