Shader "Custom/ DronesTerrain" 
{
	Properties 
	{
		_MaskTex("Mask Texture", 2D) = "white"{}
		//_Color1("Color 1", Color) = (0, 0, 0, 0)
		_Texture1("Texture 1", 2D) = "white"{}
		_RMult("Multiplier", Float) = 1
		//_Color2("Color 2", Color) = (0, 0, 0, 0)
		_Texture2("Texture 2", 2D) = "white"{}
		_GMult("Multiplier", Float) = 1
		//_Color3("Color 3", Color) = (0, 0, 0, 0)
		_Texture3("Texture 3", 2D) = "white"{}
		_BMult("Multiplier", Float) = 1
		//_Color4("Color 4", Color) = (0, 0, 0, 0)
		_Texture4("Texture 4", 2D) = "white"{}

		_LightMapMult("Light Map Mult", Float) = 1
		_LightMapAdd("Light Map Add", Float) = 0
		_LightMapOverall("Light Map Overall", Float) = 1
		_HeightFogFactor("height Fog Factor", Float) = 100
		
	}


	CGINCLUDE

		#include "UnityCG.cginc"
		#include "Include/ShaderSupport.cginc"
		//#include "UnityStandardUtils.cginc"
		//#include "UnityStandardInput.cginc"
		//#include "UnityStandardBRDF.cginc"
		//#include "UnityStandardCore.cginc"
			
		#include "AutoLight.cginc"

		half4 _Color1, _Color2, Color3, _Color4;

		sampler2D _Texture1, _Texture2, _Texture3, _Texture4;
		float4 _Texture1_ST, _Texture2_ST, _Texture3_ST, _Texture4_ST;

		sampler2D _MaskTex;
		half4 _MaskTex_ST;

		// sampler2D unity_Lightmap;

		// float4 unity_LightmapST;

		struct v2f
		{
			float4 vPos					: POSITION0;
			half2 vTexCoord0			: TEXCOORD0;
			half2 vTexCoord1			: TEXCOORD1;
			half2 vTexCoord2			: TEXCOORD2;
			half2 vTexCoord3			: TEXCOORD3;
			half2 vTexCoord				: TEXCOORD4;
			half4 ambientOrLightmapUV	: TEXCOORD5;	// SH or Lightmap UV

			FOG_COLOR_COORD(0)
			PROJ_COORD(6)
			//half3 vertexLights			: TEXCOORD6;
				
		};

		v2f vert_Terrain(appdata_full v)
		{
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f, o);

			o.vPos = mul(UNITY_MATRIX_MVP, v.vertex);

			o.vTexCoord0 = TRANSFORM_TEX(v.texcoord, _Texture1);
			o.vTexCoord1 = TRANSFORM_TEX(v.texcoord, _Texture2).xy;

			o.vTexCoord2 = TRANSFORM_TEX(v.texcoord, _Texture3).xy;
			o.vTexCoord3 = TRANSFORM_TEX(v.texcoord, _Texture4).xy;

			float norX = abs(v.normal.x);
            float norY = abs(v.normal.y);
            float norZ = abs(v.normal.z);    

            float total = (norX + norY + norZ);
            norX /= total;
            norY /= total;
            norZ /= total;

			o.vTexCoord = TRANSFORM_TEX(v.texcoord, _MaskTex);				
			o.ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

			//o.vertexLights = ShadeVertexLights(v.vertex, v.normal);

			APPLY_FOG(o);
			GEN_PROJ_COORD(o);

			return o;
		}

		half4 blendTexture(half4 texA, half multA, half4 texB, half multB)
		{
			half4 mixColor;				
			multA = saturate(multA * 2);
			mixColor = texA * multA + texB * multB;

			return mixColor;
		}

		half _LightMapMult, _LightMapAdd, _LightMapOverall;
		
		half _RMult, _GMult, _BMult;
		half _FogMult;


		half4 frag_Terrain(v2f IN) : COLOR0
		{
			half4 finalColor = half4(0, 0, 0, 0);

			half4 mask = tex2D(_MaskTex, IN.vTexCoord);
				
			finalColor = tex2D(_Texture1, IN.vTexCoord0) * mask.r * _RMult;
			finalColor += tex2D(_Texture2, IN.vTexCoord1) * mask.g * _GMult;				
			finalColor += tex2D(_Texture3, IN.vTexCoord2) * mask.b * _BMult;
			finalColor += tex2D(_Texture4, IN.vTexCoord3) * saturate(1 - (mask.r + mask.g + mask.b));

			half cloudShadow1 = 0;
			APPLY_VOL_FOG(cloudShadow1);

				
				
			half cloudShadow = (cloudShadow1) * 0.4 + 0.7;
				
				
				fixed4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.ambientOrLightmapUV.xy); 
				//bakedColorTex = lerp(cloudShadow.r, bakedColorTex, saturate(cloudShadow.r));
				//bakedColorTex *= cloudShadow;
					
				half3 bakedColor = DecodeLightmap(bakedColorTex);
				bakedColor = bakedColor * _LightMapMult + _LightMapAdd;
				bakedColor *= _LightMapOverall;
				//#ifdef DIRLIGHTMAP_OFF
				#if !FLIR && !FLIR_BLACK
					finalColor.rgb *= (bakedColor);
				#endif
				//#endif

			//finalColor.rgb = finalColor.rgb + finalColor.rgb * IN.vertexLights;
				
			finalColor.rgb = lerp(finalColor.rgb, finalColor.rgb * finalColor.rgb, 0.5) * 1.2;				

			#if !FLIR && !FLIR_BLACK
				finalColor.rgb = lerp(finalColor.rgb, FOG_COLOR, (FOG_FACTOR * saturate(cloudShadow1 * 0.5 + 0.8)) * _FogMult);
			#endif

			#if FLIR || FLIR_BLACK
			finalColor.rgb = lerp(finalColor.rgb, half3(0.4, 0.4, 0.4), 0.5);
			#endif
				
			finalColor.a = 0;				

			return finalColor;
		}
		
		half4 frag_Terrain_vertexLit(v2f IN) : COLOR0
		{
			half4 finalColor = half4(0, 0, 0, 0);

			half4 mask = tex2D(_MaskTex, IN.vTexCoord);
				
			finalColor = tex2D(_Texture1, IN.vTexCoord0) * mask.r * _RMult;
			finalColor += tex2D(_Texture2, IN.vTexCoord1) * mask.g * _GMult;				
			finalColor += tex2D(_Texture3, IN.vTexCoord2) * mask.b * _BMult;
			finalColor += tex2D(_Texture4, IN.vTexCoord3) * saturate(1 - (mask.r + mask.g + mask.b));

			half cloudShadow1 = 0;
			APPLY_VOL_FOG(cloudShadow1);

				
				
			half cloudShadow = (cloudShadow1) * 0.4 + 0.7;
				
				

			//finalColor.rgb = finalColor.rgb + finalColor.rgb * IN.vertexLights;
				
			finalColor.rgb = lerp(finalColor.rgb, finalColor.rgb * finalColor.rgb, 0.5) * 1.2;				

			#if !FLIR && !FLIR_BLACK
				finalColor.rgb = lerp(finalColor.rgb, FOG_COLOR, (FOG_FACTOR * saturate(cloudShadow1 * 0.5 + 0.8)) * _FogMult);
			#endif

			#if FLIR || FLIR_BLACK
			finalColor.rgb = lerp(finalColor.rgb, half3(0.4, 0.4, 0.4), 0.5);
			#endif
				
			finalColor.a = 0;				

			return finalColor;
		}


	ENDCG

	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		

		Pass
		{			
			
			Tags 
			{ 
				"RenderType"="Opaque" 	
				"LightMode" = "VertexLMRGBM"
			}
		
			CGPROGRAM

			#pragma vertex vert_Terrain
			#pragma fragment frag_Terrain
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

			#pragma vertex vert_Terrain
			#pragma fragment frag_Terrain
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

			#pragma vertex vert_Terrain
			#pragma fragment frag_Terrain
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			#pragma multi_compile WORLD_SPACE VIEW_SPACE 			

			#pragma target 3.0		
			
			ENDCG
		}
		
	} 
	FallBack Off
}
