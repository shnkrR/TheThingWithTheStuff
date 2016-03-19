Shader "Custom/ShieldNew" 
{
	Properties 
	{
		[HDR]_ShieldColor("Shield Color", Color) = (1, 1, 1, 1)
		_MainTex("Electric Texture", 2D) = "black"{}
		[HideInInspector]_CollisionMult("Collision Multiplier", Float) = 0
		[HideInInspector]_CollisionTime("Collision Time", Float) = -3
		_ClipRange("Clip Range", Range(0, 6)) = -20
		_Seamless("Seamless Texture", 2D) = "black"{}
		_ShieldOpacity("Shield Opacity", Range(0, 1)) = 0.2
		_ShieldEffectMult("Shield Effect Multiplier", Float) = 1
		//_Shield
	}
	SubShader 
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		LOD 200
		//Cull Off
		//ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		//GrabPass {}	
		
		Pass
		{
			
			
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

			sampler2D _GrabTexture;
			float4 _GrabTexture_TexelSize;
			half4 _EdgeColor;

			sampler2D _NoiseBump;
			
			sampler2D _Seamless;
			
			half _ShieldOpacity;			
			half _ShieldEffectMult;
			half3 _GeneratePos;

			struct v2f
			{
				float4 vPos					: POSITION0;
				half2 vTexCoord				: TEXCOORD0;				
				half3 vWorldNormal			: TEXCOORD1;
				half3 vViewDir				: TEXCOORD2;									
				half3 vWorldPos				: TEXCOORD3;
				half3 vObjectPos			: TEXCOORD4;
				half3 vGenPos				: TEXCOORD5;
			};
			half3 _ImpactPos;
			v2f vert_Terrain(appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				o.vPos = mul(UNITY_MATRIX_MVP, v.vertex);
				float4 vWorldPos = mul(_Object2World, v.vertex);
				o.vObjectPos = mul(_World2Object, half4(_ImpactPos.xyz, 1)).xyz;
				o.vGenPos = mul(_World2Object, half4(_GeneratePos.xyz, 1)).xyz;
				
				o.vWorldNormal = UnityObjectToWorldNormal(v.normal);
				o.vTexCoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.vViewDir = (vWorldPos - _WorldSpaceCameraPos.xyz);
				
				o.vWorldPos = (v.vertex.xyz);				

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

			sampler2D _ScrollTex;
			sampler2D _WobbleTex;

			sampler2D _NormalMap;
			sampler2D _SpecularMap;
			half _SpecMultiplier;
			half _Roughness;
			sampler2D _TireStreaks;
			samplerCUBE _Cube;
			half4 _ShieldColor;
			half3 _ImpactPosition;		
			sampler2D _NoiseMap;
			half _ClipRange;
			
			
			
sampler2D _NoiseTex;
sampler2D _ElecTex;
sampler2D _ElecMask;

			float SphereMask(float3 vec1, float3 vec2, float _SunSize)
			{
				float3 delta = vec1 - vec2;
				half V1oV2 = dot(vec1, delta);
				float dist = saturate(V1oV2);
				//float dist = length(delta);
				
				float spot = 1.0 - smoothstep(0.0, _SunSize, dist);				
				return spot * spot * spot;
			}
			
			float SphereMask1(float3 vec1, float3 vec2, float _SunSize)
			{
				float3 delta = vec1 - vec2;
				half V1oV2 = dot(vec1, delta);
				//float dist = saturate(V1oV2);
				float dist = length(delta);
				
				float spot = 1.0 - smoothstep(0.0, _SunSize, dist);				
				return spot * spot * spot;
			}

			half _CollisionMult;
			half _CollisionTime;

			half4 frag_Terrain(v2f IN) : COLOR0
			{
				half4 finalColor = half4(0, 0, 0, 0);				

				half sphereMask = SphereMask(normalize(IN.vObjectPos), normalize(IN.vWorldPos), 0.02f) * 3;
				sphereMask = saturate(sin(_CollisionTime + sphereMask) * sphereMask);
				
				half genMask = SphereMask1(normalize(IN.vGenPos), normalize(IN.vWorldPos), _ClipRange) * 3;				
				
				

				
				
				half seamless = tex2D(_Seamless, IN.vTexCoord + _Time.x).r;
				seamless = tex2D(_Seamless, IN.vTexCoord - _Time.x).r;
				IN.vTexCoord.xy += (seamless * 2 - 1) * 0.1;
				

				//return heightFact;

				//half glowMask = saturate(prevHeightFact - heightFact);					
				


				half4 elecTex = tex2D(_MainTex, IN.vTexCoord) * _ShieldEffectMult;
				elecTex.a = elecTex.r;
				//elecTex *= tex2D(_ElecTex, IN.vTexCoord + half2(0.5, 0.5) - _Time.x);				
				
				//return elecTex;
				
				half3 vNormal = IN.vWorldNormal;
			
				float3 vRefl = (reflect(IN.vViewDir, vNormal));
				half3 env = texCUBElod(_Cube, half4(vRefl, 0.5));

				half NoV = saturate(1 - dot(IN.vWorldNormal, normalize(-IN.vViewDir)));
				half NoV1 = NoV * NoV * NoV;
				

				finalColor = elecTex * _ShieldColor + _ShieldColor;
				finalColor = finalColor * NoV1 + elecTex * _ShieldColor + _ShieldColor * _ShieldOpacity + elecTex * sphereMask * 4;// * _CollisionMult;				
			
#if NIGHTVISION
				finalColor *= 0.5;
#endif

				return finalColor * genMask;
			}

			ENDCG
		}
	} 
	FallBack "Diffuse"
}
