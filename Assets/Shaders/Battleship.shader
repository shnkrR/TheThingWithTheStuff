Shader "Custom/Battleship" 
{
	Properties 
	{
		_MainTex("Main Texture", 2D) = "white"{}		
		_SpecularMap("Specular", 2D) = "black"{}
		_NormalMap("Normal Map", 2D) = "bump"{}
		_TireStreaks("Tire Streaks", 2D) = "white"{}
		_SpecMultiplier("Spec Multiplier", Float) = 0.5
		_Roughness("Roughness", Float)	= 0.25
		_Cube("Reflection Cube", CUBE) = "skybox"{}
		_Metallic("Metallic", Range(0, 1)) = 0.5
		_HeightFogFactor("height Fog Factor", Float) = 100

	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass
		{
			Tags{ "RenderType" = "Opaque"}
			Lighting On
			CGPROGRAM

			#pragma vertex vert_Terrain
			#pragma fragment frag_Terrain	
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV


			#pragma target 3.0

			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
			#include "UnityStandardInput.cginc"
			#include "UnityStandardBRDF.cginc"
			#include "UnityStandardCore.cginc"
			#include "AutoLight.cginc"
			#include "Include/ShaderSupport.cginc"

			struct v2f
			{
				float4 vPos					: POSITION0;
				half4 vTexCoord				: TEXCOORD0;				
				half3 vWorldNormal			: TEXCOORD1;
				half3 vWorldTangent			: TEXCOORD2;
				half3 vWorldBinormal		: TEXCOORD3;
				half3 vViewDir				: TEXCOORD4;
				FOG_COORD(5)
				PROJ_COORD(6)
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


				o.vTexCoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.vTexCoord.zw = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				

				o.vViewDir = (vWorldPos - _WorldSpaceCameraPos.xyz);

				APPLY_FOG(o);
				GEN_PROJ_COORD(o);

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
				half4 finalColor = half4(0, 0, 0, 1);

				finalColor = tex2D(_MainTex, IN.vTexCoord.xy);				
				half3 specularColor = finalColor.rgb * _Metallic;
				finalColor.rgb = finalColor.rgb - finalColor.rgb * _Metallic;
				//return half4(specularColor, 1);

				half3 vNormal = UnpackNormal(tex2D(_NormalMap, IN.vTexCoord.xy));
				half3x3 local2WorldTranspose = half3x3((IN.vWorldTangent), (IN.vWorldBinormal), (IN.vWorldNormal));
				vNormal = normalize(mul(vNormal, local2WorldTranspose));

				float3 vRefl = (reflect(IN.vViewDir, vNormal));
				float RdotL = saturate(dot(normalize(vRefl), _WorldSpaceLightPos0.xyz));
				half tire = tex2D(_TireStreaks, IN.vTexCoord.xy * 4);
				half roughness = _Roughness;
				
				half specDirLight = D_Approx(roughness, RdotL) * _LightColor0.rgb * tex2D(_SpecularMap, IN.vTexCoord.xy).a * _SpecMultiplier;
				
				half3 env = texCUBElod(_Cube, half4(vRefl, 3));
				//env = env * env;
				//#if defined(LIGHTMAP_ON)
				fixed4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.vTexCoord.zw);
				
				half3 bakedColor = DecodeLightmap(bakedColorTex);
				//#ifdef DIRLIGHTMAP_OFF
				finalColor.rgb += specDirLight + env * specularColor * 2;// * (1 - tire);
				//finalColor.rgb *= (IN.shLight.rgb * 0.5);
				
				//#endif
				//#endif	

				#if FLIR || FLIR_BLACK
					finalColor.rgb = lerp(finalColor.rgb, half3(0.4, 0.4, 0.4), 0.5);
				#endif

				half volTex = 1;
				APPLY_VOL_FOG(volTex);
				finalColor.rgb = lerp(finalColor.rgb, FogColor, saturate(IN.fogParams.x * (volTex * 0.5 + 0.8)));



				#if NIGHTVISION
					finalColor.a = 0;
				#endif

				
				return saturate(finalColor);
			}

			ENDCG
		}
	} 
	FallBack "Diffuse"
}
