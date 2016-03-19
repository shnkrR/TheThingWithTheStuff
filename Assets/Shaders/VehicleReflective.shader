Shader "Custom/VehicleReflective" 
{
	Properties 
	{
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness("Brightness", Float) = 1
		_Cube("Reflection Cube", CUBE) = "skybox"{}
		_ReflMult("Refl Multiplier", Float) = 5	
		[HDR]_GlowColor("Glow Color", Color) = (1, 1, 1, 1)		
		_Roughness("Roughness", Range(0, 1)) = 0.5
		_ReflAdd("Refl Add", Float) = 0
		_Fresnel("Fresnel Pow", Float) = 1
		_LightMapMult("Light Map Mult", Float) = 1
		_LightMapAdd("Light Map Add", Float) = 0
		_HeightFogFactor("height Fog Factor", Float) = 100
	}


	CGINCLUDE

		#include "UnityCG.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityStandardInput.cginc"
		#include "UnityStandardBRDF.cginc"
		#include "UnityStandardCore.cginc"
		#include "AutoLight.cginc"
		#include "Include/ShaderSupport.cginc"

		samplerCUBE _ReflectCube;
		half4 _GlowColor;
			
			
		half _ReflectionMult;
		half _Brightness;	
		half4 _VehicleGlowColor;	
			
			
		struct appdata 
		{
			float4 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 normal : NORMAL0;
		};
		
		half4 _VehicleColor;

		struct v2f_surf 
		{
			float4 pos			: SV_POSITION;
			half2 uv_MainTex	: TEXCOORD0;
			half2 lmap			: TEXCOORD1;
			half3 vRefl			: TEXCOORD2;
			half3 vWorldNormal	: TEXCOORD3;
			half3 vViewDir		: TEXCOORD4;
			FOG_COORD(5)				
			PROJ_COORD(6)
			//half3 vertexLights	: TEXCOORD7;
		};

		uniform float4x4 _IdentityMatrix;
		half _Roughness;
		half3 _LightOffset;

		half D_Approx( half Roughness, half RoL )
		{
			half a = Roughness * Roughness;				
			float rcp_a2 = 1 / (a);
				
			half c = 0.72134752 * rcp_a2 + 0.39674113;
			return rcp_a2 * exp2( c * RoL - c );
		}
		
		v2f_surf vert_surf (appdata v) 
		{
			v2f_surf o;
			UNITY_INITIALIZE_OUTPUT(v2f_surf, o);
			
			float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

			half3 vWorldNormal = (UnityObjectToWorldNormal(v.normal));
			half3 vViewDir = (vWorldPos - _WorldSpaceCameraPos);
			o.vViewDir = _WorldSpaceCameraPos - vWorldPos;
			o.vWorldNormal = vWorldNormal;

			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);	
			o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;		

			//o.vertexLights = ShadeVertexLights(v.vertex, v.normal) * 5;

			//o.vertexLights = ShadeVertexLights();

			o.vRefl = reflect(vViewDir, vWorldNormal);		
			APPLY_FOG(o);
			GEN_PROJ_COORD(o);
			
			return o;
		}
		samplerCUBE _Cube;
		half _ReflMult;
		half _Fresnel;
		half _ReflAdd;			

		half _LightMapMult, _LightMapAdd;
		half _FogMult;

		half4 frag_surf (v2f_surf IN) : COLOR 
		{				
			half4 c = tex2D (_MainTex, IN.uv_MainTex);				

			half cloudShadow = 0;
			APPLY_VOL_FOG(cloudShadow);
			//return cloudShadow;

			#if !FLIR && !FLIR_BLACK

				half3 lm1 = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy));	
				lm1 = lm1 * _LightMapMult + _LightMapAdd;

				lm1 *= (cloudShadow) * 0.4 + 0.7;
				#ifndef LIGHTMAP_OFF
					c.rgb = c.rgb * lm1.rgb;				
				#endif	
							
			#endif		

			
			//c.rgb = c.rgb + c.rgb * IN.vertexLights;
			c.rgb *= _Color.rgb;

		

			half glowAmt = saturate((c.a - 0.5) * 2);
			half reflMult = c.a - glowAmt;

			//c.rgb = c.rgb - c.rgb * reflMult;
			half3 vRefl = -reflect(IN.vViewDir, IN.vWorldNormal);
			half3 env = texCUBE (_Cube, vRefl);	
			env = env * env;
				
			half NoV = 1 - saturate(dot(normalize(IN.vWorldNormal), normalize(IN.vViewDir)));
			NoV = saturate(lerp(NoV, NoV * NoV, _Fresnel));
				//return half4(env, 1);
										
			c.rgb = c.rgb * _Brightness + env * (NoV * _ReflMult * c.a + _ReflAdd);
			c.rgb = c.rgb + glowAmt * _GlowColor.rgb * _VehicleGlowColor.rgb;	
				
			//APPLY_FOG_COLOR(c, IN);
			
			c.rgb = c.rgb * _VehicleColor.rgb * 3;

			#if FLIR || FLIR_BLACK
				c.rgb = lerp(c.rgb, half3(0.4, 0.4, 0.4), 0.6);
			#else
			
				c.rgb = lerp(c.rgb, FOG_COLOR, FOG_FACTOR * saturate(cloudShadow * 0.5 + 0.8));
			#endif
			
			#if NIGHTVISION
				c.a = 0;
			#else
					//c.a = c.a * 4;
				//c.a = saturate((c.a - c.a * 0.9) * 5);
				c.a = 0.5;
			#endif
			
			
							
			//c.a = 0;				
			//OUTPUT_DEPTH(c, IN);
				
			return c;	
		}

	ENDCG


	SubShader 
	{
		
		LOD 100			
		
		Pass 
		{	
			Tags 
			{ 
				"RenderType"="Opaque" 	
				"LightMode" = "VertexLMRGBM"
			}
		
			CGPROGRAM
			
			#pragma vertex vert_surf
			#pragma fragment frag_surf

			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			#pragma multi_compile WORLD_SPACE VIEW_SPACE 
			#pragma target 3.0
			 
			

			ENDCG
		}

		Pass 
		{	
			Tags 
			{ 
				"RenderType"="Opaque" 	
				"LightMode" = "VertexLM"
			}
		
			CGPROGRAM
			
			#pragma vertex vert_surf
			#pragma fragment frag_surf

			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			#pragma multi_compile WORLD_SPACE VIEW_SPACE 
			#pragma target 3.0
			 
			

			ENDCG
		}	
		
		Pass 
		{	
			Tags 
			{ 
				"RenderType"="Opaque" 	
				"LightMode" = "Vertex"
			}
		
			CGPROGRAM
			
			#pragma vertex vert_surf
			#pragma fragment frag_surf

			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			#pragma multi_compile WORLD_SPACE VIEW_SPACE 
			#pragma target 3.0
			 
			

			ENDCG
		}	
				
	}

	FallBack "Mobile/VertexLit"
}