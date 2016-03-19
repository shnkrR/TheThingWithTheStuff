Shader "Environment/GradientSky" 
{
	Properties 
	{		
		_HorizonColor("Horizon Color", Color) = (1, 1, 1, 1)
		_ZenithColor("Zenith Color", Color) = (1, 1 , 1, 1)
		_OppHorizonColor("Opp Horizon Color", Color) = (1, 1, 1, 1)
		_SkyGradientHeight("Sky Gradient Height", Range(-1000, 1000)) = 1
		_GradientFallOff("Gradient Fall Off", Float) = 0
		_FogNoiseTexture("Fog Noise Texture", 2D) = "white" {}

		FogHeightStart("Fog Height Start", Float) = 0
		FogHeightEnd("Fog Height End", Float) = 1
		_HeightFogFactor("Height Fog Factor", Float) = 2
		_SunSize("Sun Size", Float) = 1
		_Contrast("Contrast", Float) = 0

		_SunMultiplier("Sun Multiplier", Float) = 1000
		_HaloSize("Halo Size", Float) = 1
		_HaloColor("Halo Color", Color) = (1, 1, 1, 0.2)


		//_LerpTex("Zup Zap Texture", 2D) = "white"{}
		//_LerpValue("Zup Zap Zup Value", Range(0, 1)) = 0

		//Dissolve params
		//_DissolveTexture("Dissolve Texture", 2D) = "white" {}
		//_DissolveAmount("Dissolve Amount", Range(0, 1)) = 0
		//_DissolveColor("Dissolve Color", Color) = (0, 0, 0, 0)
		//_DissolveColor1("Dissolve Color1", Color) = (0, 0, 0, 0)



		
	}
	SubShader 
	{
		Tags { "RenderType" = "Opaque" "Lightmode" = "Forwardbase"}	
		LOD 100
		Cull Off
		//ZWrite Off// ZTest Always
			
		Pass 
		{			
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma multi_compile NO_GODRAYS WITH_GODRAYS
			//#pragma fragmentoption ARB_precision_hint_fastest
			//#pragma multi_compile NO_DOF WITH_DOF
			//#pragma multi_compile DISSOLVE_OFF DISSOLVE_ON
			//#pragma multi_compile_fwdbase
                                                           
			#include "HLSLSupport.cginc"
			#include "Include/ShaderSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			uniform half _FocusDist;
			uniform half _DOFApature;

			half4 _HorizonColor;
			half4 _ZenithColor;
			half _SkyGradientHeight;

			uniform sampler2D _FogNoiseTexture;
			half _SunSize;

			

			half4 _FogNoiseTexture_ST;
			half _GodRaysSkyInfluence = 0.5;

			//Scene Saturation
			uniform half _SceneSaturation = 1;
			uniform half _Gamma = 0;
			
			half4 _SceneColor = half4(1, 1, 1, 0);

			
			half _Contrast;

			sampler2D _LerpTex;
			half _LerpValue;

			//Dissolve Params
			sampler2D _DissolveTexture;
			half _DissolveAmount;
			half4 _DissolveColor1, _DissolveColor;

			half _HaloSize;
			half4 _HaloColor;
			

			struct v2f_surf 
			{
				float4 pos : SV_POSITION;				
				//half depth : TEXCOORD0;
				float height : TEXCOORD0;	
				half fogFactor : TEXCOORD1;	
				half2 vTexCoord : TEXCOORD2;
				FOG_COORD(3)
				PROJ_COORD(4)				
				float3 rayDir : TEXCOORD5;
				half3 vWorldNormal : TEXCOORD6;
				
			};

			float3 calcSunSpot(float3 vec1, float3 vec2)
			{
				float3 delta = vec1 - vec2;
				float dist = length(delta);
				//return dist;
				float spot = 1.0 - smoothstep(0.0, _SunSize, dist);
				float spot1 = 1.0 - smoothstep(0.0, _SunSize * 4, dist);
				return float3(spot * spot, spot1, 1.0 - smoothstep(0.0, _HaloSize, dist));
			}

			
		
			v2f_surf vert_surf (appdata_full v) 
			{
				v2f_surf o;
				UNITY_INITIALIZE_OUTPUT(v2f_surf, o);
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);				
				
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;
				//o.depth = -(mul(UNITY_MATRIX_MV, v.vertex).z / 100 + _FocusDist) * _DOFApature;	
				o.height = v.vertex.y;// +_SkyGradientHeight;

				o.vTexCoord = v.texcoord;
			
				
				o.vWorldNormal = UnityObjectToWorldNormal(v.normal);
				
				APPLY_FOG(o);
				GEN_PROJ_COORD(o);
				
				o.rayDir = vWorldPos - _WorldSpaceCameraPos.xyz;

				return o;
			}
			half _GradientFallOff;
			half _SunMultiplier;
			half4 _OppHorizonColor;

			float4 frag_surf (v2f_surf IN) : COLOR 
			{
				float3 ray = normalize(IN.rayDir);

				float height = dot(half3(0, 1, 0), ray);
				height = 1 - height;
				height = saturate(pow(height, _GradientFallOff));
				//return height;
				half sunDir = dot(normalize(IN.vWorldNormal), _WorldSpaceLightPos0.xyz) * 0.5 + 0.5;
				//return sunDir;
				//float4 finalColor = float4(saturate(lerp(_ZenithColor, lerp(_OppHorizonColor, _HorizonColor, sunDir), height)).rgb, 1.0) ;
				float4 finalColor = float4(saturate(lerp(_ZenithColor, _HorizonColor, height)).rgb, 1.0) ;
				
				
				//return float4(ray, 1);
				float3 mie = calcSunSpot(_WorldSpaceLightPos0.xyz, ray);
				finalColor.rgb += mie.x * _SunMultiplier * _LightColor0.rgb + mie.z * _HaloColor.rgb * _HaloColor.a;
				//finalColor.rgb = lerp(finalColor.rgb, FogColor.rgb, IN.fogFactor);				

				finalColor.rgb = lerp(finalColor.rgb, finalColor.rgb * finalColor.rgb, _Contrast);
				
				APPLY_FOG_COLOR(finalColor, IN);
				
				

				#if WITH_GODRAYS
					finalColor.rgb *= 0.8;
				#else
					finalColor.rgb *= 1.05;
				#endif
				
				//finalColor.rgb = FOG_COLOR;
				
				//finalColor.rgb *= 1.5;
				finalColor.a =  0;//_GodRaysSkyInfluence;

				//finalColor.rgb = tex2D(_LerpTex, (IN.viewSpaceD.xy) * 0.1).rgb;
				
				
				return finalColor;
			}

			ENDCG
		}
	}

	
	

	//FallBack "Mobile/VertexLit"
}