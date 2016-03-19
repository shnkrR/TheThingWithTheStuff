Shader "Custom/EnvDepthDetail" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {} 
		_Detail ("Detail (RGB)", 2D) = "white" {}

		_Brightness("Brightness", Float) = 1		
		_FlirColor("Flir / Heat Lerp Color", Color) = (0.4, 0.4, 0.4, 0.4)
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
		LOD 200
		//ColorMask RGB

		// Non-lightmapped
		Pass 
		{
			Tags { "LightMode" = "Vertex" }
			Lighting Off
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile SIMPLE_MODE FLIR_HEAT 
			
			#pragma target 3.0					
			//#define TEXTURE_PROJECTION
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"			

			sampler2D _MainTex;
			half4 _MainTex_ST;

			half _Brightness;

			//Fog Stuff
			half4 FogColor;// = half4(0, 0, 0, 0);
			half FogStart;
			half FogEnd;
			sampler2D _Detail;
			float4 _Detail_ST;


			struct v2f_surf 
			{
				float4 pos : SV_POSITION;
				half4 uv_MainTex : TEXCOORD0;
				half ViewSpaceDepth : TEXCOORD1;
				half fogFactor : TEXCOORD2;
				half3 shLight  : TEXCOORD3;
			};

			inline half3 ShadeVertexLightsDiff(half4 vertex, half3 normal, half a_fPointLightColorMult)
			{	
				half3 viewpos = mul (UNITY_MATRIX_MV, vertex).xyz;
				half3 viewN = mul ((float3x3)UNITY_MATRIX_IT_MV, normal);
				half3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
				half3 lightColor1 = half3(0, 0, 0);
				for (int i = 0; i < 4; i++) 
				{
					half3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
					half lengthSq = dot(toLight, toLight);
					half atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
					half diff = max (0, dot (viewN, normalize(toLight)));
					lightColor1 += unity_LightColor[i].rgb * (diff * atten);
				}

				return lightColor + lightColor1 * a_fPointLightColorMult;
			}
		
			v2f_surf vert_surf (appdata_full v) 
			{
				v2f_surf o;
			
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	
				o.uv_MainTex.zw = TRANSFORM_TEX(v.texcoord, _Detail);

				
				o.ViewSpaceDepth =  mul(UNITY_MATRIX_MV, v.vertex).z;
				o.fogFactor = saturate((FogStart + o.ViewSpaceDepth) / (FogStart - FogEnd));

				o.shLight = ShadeVertexLightsDiff(v.vertex, v.normal, 5);

				return o;
			}
		
			half _LerpSpeed;
			sampler2D _DissolveTexture1;
			half _Contrast;
			half4 _FlirColor;

			half4 frag_surf (v2f_surf IN) : COLOR 
			{				
				half4 c = tex2D(_MainTex, IN.uv_MainTex.xy);
				#if FLIR_HEAT
					c.rgb = lerp(c.rgb, _FlirColor.rgb, 0.8);
					c.rgb = c.rgb * _Brightness;
				#else
					c.rgb = c.rgb * _Brightness * tex2D(_Detail, IN.uv_MainTex.zw).rgb;
				#endif
				c.rgb = c.rgb * IN.shLight;
				
				//c.rgb = lerp(c.rgb, FogColor.rgb, IN.fogFactor);				
			
				c.a = 0.0;

				return c;	
			}

			ENDCG
		}

		Pass 
		{
			Tags { "LightMode" = "VertexLM" }
		
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile SIMPLE_MODE FLIR_HEAT 
			//#define TEXTURE_PROJECTION
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"			

			sampler2D _MainTex;	
			// sampler2D unity_Lightmap;
			
		
			// half4 unity_LightmapST;
			half4 _MainTex_ST;

			half _Brightness;

			//Fog Stuff
			half4 FogColor;// = half4(0, 0, 0, 0);
			half FogStart;
			half FogEnd;

			sampler2D _Detail;
			float4 _Detail_ST;


			struct appdata_simple 
			{
				float4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;
				half4 texcoord1 : TEXCOORD1;
			};

			struct v2f_surf 
			{
				float4 pos : SV_POSITION;
				half4 uv_MainTex : TEXCOORD0;
				half2 lmap : TEXCOORD1;				
				half ViewSpaceDepth : TEXCOORD3;
				half fogFactor : TEXCOORD4;
			};
		
			v2f_surf vert_surf (appdata_full v) 
			{
				v2f_surf o;
			
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	
				o.uv_MainTex.zw = TRANSFORM_TEX(v.texcoord, _Detail);
				
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				o.ViewSpaceDepth =  mul(UNITY_MATRIX_MV, v.vertex).z;	
				o.fogFactor = saturate((FogStart + o.ViewSpaceDepth) / (FogStart - FogEnd));

				return o;
			}
		
			half _LerpSpeed;
			sampler2D _DissolveTexture1;
			half _Contrast;
			half4 _FlirColor;

			half4 frag_surf (v2f_surf IN) : COLOR 
			{				
				half4 c = 0;
				half3 lightmapData = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap));			
				
				c = tex2D (_MainTex, IN.uv_MainTex.xy);
				#if FLIR_HEAT
					c.rgb = lerp(c.rgb, _FlirColor.rgb, 0.8);
					c.rgb = c.rgb * _Brightness;
				#else
					c.rgb = c.rgb * lightmapData;
					c.rgb = c.rgb * _Brightness * tex2D(_Detail, IN.uv_MainTex.zw).rgb;
				#endif
				
				//c.rgb = lerp(c.rgb, FogColor.rgb, IN.fogFactor);				
				c.a = 0.0;

				return c;	
			}

			ENDCG
		}
		
		Pass 
		{
			Tags { "LightMode" = "VertexLMRGBM" }
		
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile SIMPLE_MODE FLIR_HEAT 
			
			//#define TEXTURE_PROJECTION
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"			

			sampler2D _MainTex;	
			// sampler2D unity_Lightmap;
			
		
			// half4 unity_LightmapST;
			half4 _MainTex_ST;

			half _Brightness;

			//Fog Stuff
			half4 FogColor;// = half4(0, 0, 0, 0);
			half FogStart;
			half FogEnd;

			sampler2D _Detail;
			float4 _Detail_ST;


			struct appdata_simple 
			{
				float4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;
				half4 texcoord1 : TEXCOORD1;
			};

			struct v2f_surf 
			{
				float4 pos : SV_POSITION;
				half4 uv_MainTex : TEXCOORD0;
				half2 lmap : TEXCOORD1;				
				half ViewSpaceDepth : TEXCOORD3;
				half fogFactor : TEXCOORD4;
			};
		
			v2f_surf vert_surf (appdata_full v) 
			{
				v2f_surf o;
			
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	
				o.uv_MainTex.zw = TRANSFORM_TEX(v.texcoord, _Detail);
				
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				o.ViewSpaceDepth =  mul(UNITY_MATRIX_MV, v.vertex).z;
				o.fogFactor = saturate((FogStart + o.ViewSpaceDepth) / (FogStart - FogEnd));

				return o;
			}
		
			half _LerpSpeed;
			sampler2D _DissolveTexture1;	
			half4 _FlirColor;		

			half4 frag_surf (v2f_surf IN) : COLOR 
			{				
				half4 c = 0;
				half3 lightmapData = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap));			
				
				c = tex2D (_MainTex, IN.uv_MainTex.xy);

				#if FLIR_HEAT
					c.rgb = lerp(c.rgb, _FlirColor.rgb, 0.8);
					c.rgb = c.rgb * _Brightness;
				#else
					c.rgb = c.rgb * lightmapData;
					c.rgb = c.rgb * _Brightness * tex2D(_Detail, IN.uv_MainTex.zw).rgb;
				#endif			

				c.a = 0.0;
				return c;	
			}

			ENDCG
		}
	}

	SubShader 
	{
		Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
		LOD 100
		//ColorMask RGB

		// Non-lightmapped
		Pass 
		{
			Tags { "LightMode" = "Vertex" }
			Lighting Off
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			
			#pragma target 3.0					
			//#define TEXTURE_PROJECTION
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "../Include/VisionBase.cginc"

			sampler2D _MainTex;
			half4 _MainTex_ST;

			half _Brightness;

			//Fog Stuff
			half4 FogColor;// = half4(0, 0, 0, 0);
			half FogStart;
			half FogEnd;
			sampler2D _Detail;
			float4 _Detail_ST;


			struct v2f_surf 
			{
				float4 pos : SV_POSITION;
				half4 uv_MainTex : TEXCOORD0;
				half ViewSpaceDepth : TEXCOORD1;
				half fogFactor : TEXCOORD2;
				half3 shLight  : TEXCOORD3;
			};

			inline half3 ShadeVertexLightsDiff(half4 vertex, half3 normal, half a_fPointLightColorMult)
			{	
				half3 viewpos = mul (UNITY_MATRIX_MV, vertex).xyz;
				half3 viewN = mul ((float3x3)UNITY_MATRIX_IT_MV, normal);
				half3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
				half3 lightColor1 = half3(0, 0, 0);
				for (int i = 0; i < 4; i++) 
				{
					half3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
					half lengthSq = dot(toLight, toLight);
					half atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
					half diff = max (0, dot (viewN, normalize(toLight)));
					lightColor1 += unity_LightColor[i].rgb * (diff * atten);
				}

				return lightColor + lightColor1 * a_fPointLightColorMult;
			}
		
			v2f_surf vert_surf (appdata_full v) 
			{
				v2f_surf o;
			
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	
				o.uv_MainTex.zw = TRANSFORM_TEX(v.texcoord, _Detail);

				
				o.ViewSpaceDepth =  mul(UNITY_MATRIX_MV, v.vertex).z;
				o.fogFactor = saturate((FogStart + o.ViewSpaceDepth) / (FogStart - FogEnd));

				o.shLight = ShadeVertexLightsDiff(v.vertex, v.normal, 5);

				return o;
			}
		
			half _LerpSpeed;
			sampler2D _DissolveTexture1;
			half _Contrast;
			half4 _FlirColor;

			half4 frag_surf (v2f_surf IN) : COLOR 
			{				
				half4 c = tex2D(_MainTex, IN.uv_MainTex.xy);				
				c.rgb = c.rgb * _Brightness * tex2D(_Detail, IN.uv_MainTex.zw).rgb;				
				c.rgb = c.rgb * IN.shLight;	
				c.a = 0;

				#if FLIR || FLIR_BLACK || HEATVISION
					c.rgb = lerp(c.rgb, _FlirColor.rgb, 0.8);
				#endif

				c = GetCurrectOp(c);

				
				
			
				c.a = 0.0;

				return c;	
			}

			ENDCG
		}

		Pass 
		{
			Tags { "LightMode" = "VertexLM" }
		
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile  SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			//#define TEXTURE_PROJECTION
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"	
			#include "../Include/VisionBase.cginc"		

			sampler2D _MainTex;	
			// sampler2D unity_Lightmap;
			
		
			// half4 unity_LightmapST;
			half4 _MainTex_ST;

			half _Brightness;

			//Fog Stuff
			half4 FogColor;// = half4(0, 0, 0, 0);
			half FogStart;
			half FogEnd;

			sampler2D _Detail;
			float4 _Detail_ST;


			struct appdata_simple 
			{
				float4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;
				half4 texcoord1 : TEXCOORD1;
			};

			struct v2f_surf 
			{
				float4 pos : SV_POSITION;
				half4 uv_MainTex : TEXCOORD0;
				half2 lmap : TEXCOORD1;				
				half ViewSpaceDepth : TEXCOORD3;
				half fogFactor : TEXCOORD4;
			};
		
			v2f_surf vert_surf (appdata_full v) 
			{
				v2f_surf o;
			
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	
				o.uv_MainTex.zw = TRANSFORM_TEX(v.texcoord, _Detail);
				
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				o.ViewSpaceDepth =  mul(UNITY_MATRIX_MV, v.vertex).z;	
				o.fogFactor = saturate((FogStart + o.ViewSpaceDepth) / (FogStart - FogEnd));

				return o;
			}
		
			half _LerpSpeed;
			sampler2D _DissolveTexture1;
			half _Contrast;
			half4 _FlirColor;

			half4 frag_surf (v2f_surf IN) : COLOR 
			{				
				half4 c = 0;
				half3 lightmapData = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap));			
				
				c = tex2D (_MainTex, IN.uv_MainTex.xy);
				#if SIMPLE_MODE || NIGHTVISION
					c.rgb = c.rgb * lightmapData;
					c.rgb *= tex2D(_Detail, IN.uv_MainTex.zw).rgb;
				#endif

				c.rgb = c.rgb * _Brightness;

				#if FLIR || FLIR_BLACK || HEATVISION || ENV
					c.rgb = lerp(c.rgb, _FlirColor.rgb, 0.8);
				#endif
								
				c.a = 0;
				c = GetCurrectOp(c);
								
				//c.rgb = lerp(c.rgb, FogColor.rgb, IN.fogFactor);

				return c;	
			}

			ENDCG
		}
		
		Pass 
		{
			Tags { "LightMode" = "VertexLMRGBM" }
		
			CGPROGRAM
		
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile  SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			
			//#define TEXTURE_PROJECTION
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "../Include/VisionBase.cginc"			

			sampler2D _MainTex;	
			// sampler2D unity_Lightmap;
			
		
			// half4 unity_LightmapST;
			half4 _MainTex_ST;

			half _Brightness;

			//Fog Stuff
			half4 FogColor;// = half4(0, 0, 0, 0);
			half FogStart;
			half FogEnd;

			sampler2D _Detail;
			float4 _Detail_ST;


			struct appdata_simple 
			{
				float4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;
				half4 texcoord1 : TEXCOORD1;
			};

			struct v2f_surf 
			{
				float4 pos : SV_POSITION;
				half4 uv_MainTex : TEXCOORD0;
				half2 lmap : TEXCOORD1;				
				half ViewSpaceDepth : TEXCOORD3;
				half fogFactor : TEXCOORD4;
			};
		
			v2f_surf vert_surf (appdata_full v) 
			{
				v2f_surf o;
			
				float3 vWorldPos = mul(_Object2World, v.vertex).xyz;

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	
				o.uv_MainTex.zw = TRANSFORM_TEX(v.texcoord, _Detail);
				
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				o.ViewSpaceDepth =  mul(UNITY_MATRIX_MV, v.vertex).z;
				o.fogFactor = saturate((FogStart + o.ViewSpaceDepth) / (FogStart - FogEnd));

				return o;
			}
		
			half _LerpSpeed;
			sampler2D _DissolveTexture1;	
			half4 _FlirColor;		

			half4 frag_surf (v2f_surf IN) : COLOR 
			{				
				half4 c = 0;
				half3 lightmapData = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap));			
				
				c = tex2D (_MainTex, IN.uv_MainTex.xy);
				#if SIMPLE_MODE || NIGHTVISION
					c.rgb = c.rgb * lightmapData;
					c.rgb *= tex2D(_Detail, IN.uv_MainTex.zw).rgb;
				#endif

				c.rgb = c.rgb * _Brightness;
				
				c.a = 0;

				#if FLIR || FLIR_BLACK || HEATVISION || ENV
					c.rgb = lerp(c.rgb, _FlirColor.rgb, 0.8);
				#endif

				c = GetCurrectOp(c); 
								
				//c.rgb = lerp(c.rgb, FogColor.rgb, IN.fogFactor);

				return c;	
			}

			ENDCG
		}
	}

	FallBack "Mobile/VertexLit"
}