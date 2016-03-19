Shader "Custom/RoadPBS" 
{
	Properties 
	{
		_MainTex("Main Texture", 2D) = "white"{}		
		_SpecularMap("Specular", 2D) = "white"{}
		_NormalMap("Normal Map", 2D) = "bump"{}
		_TireStreaks("Tire Streaks", 2D) = "white"{}
		_SpecMultiplier("Spec Multiplier", Float) = 0.5
		_Roughness("Roughness", Float)	= 0.25
		_Cube("Reflection Cube", CUBE) = "skybox"{}

	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		
		Pass
		{
			Tags{ "RenderType" = "Opaque" }
			//Lighting On
			CGPROGRAM

			#pragma vertex vert_Terrain
			#pragma fragment frag_Terrain			


			#pragma target 3.0

			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
			#include "UnityStandardInput.cginc"
			#include "UnityStandardBRDF.cginc"
			#include "UnityStandardCore.cginc"
			#include "AutoLight.cginc"

			struct v2f
			{
				float4 vPos					: POSITION0;
				half2 vTexCoord				: TEXCOORD0;
				half4 ambientOrLightmapUV	: TEXCOORD1;
				half4 shLight				: TEXCOORD2;		
				half3 vWorldNormal			: TEXCOORD3;
				half3 vWorldTangent			: TEXCOORD4;
				half3 vWorldBinormal		: TEXCOORD5;
				half3 vViewDir				: TEXCOORD6;
			};

			v2f vert_Terrain(appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				o.vPos = mul(UNITY_MATRIX_MVP, v.vertex);
				float4 vWorldPos = mul(_Object2World, v.vertex);
				
				o.vWorldNormal = UnityObjectToWorldNormal(v.normal);
				o.vWorldTangent = normalize((mul(_Object2World, float4(v.tangent.xyz, 0.0))).xyz);
				o.vWorldBinormal = normalize(cross(o.vWorldNormal, o.vWorldTangent) * v.tangent.w);


				o.vTexCoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;


				o.shLight.rgb = ShadeVertexLights(v.vertex, v.normal);

				o.vViewDir = (vWorldPos - _WorldSpaceCameraPos.xyz);

				COMPUTE_EYEDEPTH(o.shLight.w);

				return o;
			}

			half D_Approx(half Roughness, half RoL)
			{
				half a = Roughness * Roughness;
				half a2 = a * a;
				half rcp_a2 = 1.0f / a2;
				// 0.5 / ln(2), 0.275 / ln(2)
				half c = 0.72134752 * rcp_a2 + 0.39674113;
				return rcp_a2 * exp2(c * RoL - c);
			}

			sampler2D _NormalMap;
			sampler2D _SpecularMap;
			half _SpecMultiplier;
			half _Roughness;
			sampler2D _TireStreaks;
			samplerCUBE _Cube;

			half4 frag_Terrain(v2f IN) : COLOR0
			{
				half4 finalColor = half4(0, 0, 0, 0);

				finalColor = tex2D(_MainTex, IN.vTexCoord);
				
				half tire = tex2D(_TireStreaks, IN.ambientOrLightmapUV * 9);
				

				half3 vNormal = UnpackNormal(tex2D(_NormalMap, IN.vTexCoord));
				vNormal = lerp(half3(0, 0, 1), vNormal, saturate(tire * tire));								

				half3x3 local2WorldTranspose = half3x3((IN.vWorldTangent), (IN.vWorldBinormal), (IN.vWorldNormal));
				vNormal = normalize(mul(vNormal, local2WorldTranspose));

				float3 vRefl = (reflect(IN.vViewDir, vNormal));
				float RdotL = saturate(dot(normalize(vRefl), _WorldSpaceLightPos0.xyz));
				
				half roughness = lerp(0.15, _Roughness, tire);
				
				half specDirLight = D_Approx(roughness, RdotL) * _LightColor0.rgb * tex2D(_SpecularMap, IN.vTexCoord) * _SpecMultiplier;
				
				half3 env = texCUBE(_Cube, vRefl);
				env = env * env;
				//#if defined(LIGHTMAP_ON)
				fixed4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.ambientOrLightmapUV.xy);
				half3 bakedColor = DecodeLightmap(bakedColorTex);
				//#ifdef DIRLIGHTMAP_OFF
				finalColor.rgb += specDirLight + env * (1 - roughness) * (1 - tire) * 0;
				finalColor.rgb *= (bakedColor * 0.5 + 0.2);// + IN.shLight.rgb * 0.5);
				
				//#endif
				//#endif	




				finalColor.a = 1 - IN.shLight.w / 50;
				return finalColor;
			}

			ENDCG
		}
	} 
	FallBack "Diffuse"
}
