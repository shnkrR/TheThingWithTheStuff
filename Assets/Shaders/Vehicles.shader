Shader "Custom/Vehicle" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}	
		_HeightFogFactor("height Fog Factor", Float) = 20
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque"}
		LOD 200		
		
		
		
		
		// Non-lightmapped
		Pass 
		{
			
			Lighting Off
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			#pragma multi_compile WORLD_SPACE VIEW_SPACE 
			//#define TEXTURE_PROJECTION
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"	
			#include "Include/VisionBase.cginc"
			#include "Include/ShaderSupport.cginc"

			sampler2D _MainTex;
			half4 _MainTex_ST;

			half _Brightness;

			//Fog Stuff
			//half4 FogColor;// = half4(0, 0, 0, 0);
			//half FogStart;
			//half FogEnd;
			
			half4 _VehicleColor;


			struct v2f_surf 
			{
				float4 pos : SV_POSITION;
				half2 uv_MainTex : TEXCOORD0;
				half ViewSpaceDepth : TEXCOORD1;				
				half4 color : COLOR0;
				FOG_COORD(2)
				PROJ_COORD(3)
				//half3 vertexLights : TEXCOORD4;
			};

			struct appdata_t
			{
				float4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;
				half4 color : COLOR0;
				half3 normal : NORMAL;
			};
		
			v2f_surf vert_surf (appdata_t v) 
			{
				v2f_surf o;
			
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);	
				
				o.ViewSpaceDepth =  mul(UNITY_MATRIX_MV, v.vertex).z;				
				o.color = v.color;

				//o.vertexLights = ShadeVertexLights(v.vertex, v.normal) * 5;

				APPLY_FOG(o);
				GEN_PROJ_COORD(o);

				return o;
			}
		
			half _LerpSpeed;
			sampler2D _DissolveTexture1;
			half _Contrast;

			half4 frag_surf (v2f_surf IN) : COLOR 
			{
				half cloudShadow1 = 0;
				APPLY_VOL_FOG(cloudShadow1);
				//half cloudShadow = (cloudShadow1) * 0.4 + 0.7;				

				half4 c = tex2D (_MainTex, IN.uv_MainTex);
				//c.rgb = c.rgb + c.rgb * IN.vertexLights;
				#if FLIR || FLIR_BLACK
					c.rgb = lerp(c.rgb, half3(0.4, 0.4, 0.4), 0.5);
				#else
					c.rgb = lerp(c.rgb, FOG_COLOR, (FOG_FACTOR * saturate(cloudShadow1 * 0.5 + 0.95)));
				#endif

				//return FOG_FACTOR * (cloudShadow1 * 0.5 + 0.5);

				c.rgb = c.rgb * _VehicleColor.rgb;

				#if NIGHTVISION
					c.a = 0;
				#else
					//c.a = c.a * 4;
					c.a = saturate((c.a - c.a * 0.9) * 5);
				#endif
				
				//c.a = 0;
				
					
				return c;	
			}

			ENDCG
		}
	}
		
	FallBack "Mobile/VertexLit"
}