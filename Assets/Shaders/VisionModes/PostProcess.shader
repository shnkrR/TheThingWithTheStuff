Shader "Hidden/PostProcessShader" 
{
	Properties 
	{
		_MainTex("Base", 2D) = "" {}
	}

	CGINCLUDE

		#include "UnityCG.cginc"
		#include "HLSLSupport.cginc"


		sampler2D _MainTex;
		float4 _MainTex_TexelSize;

		//Bloom params
		//.x - Threshold
		//.y - Blur Amount
		//.z - Bloom Multiplier
		half4 _BloomParams;		
		sampler2D _Bloom;
		sampler2D _Bloom2;

		//Lens Flares
		sampler2D _LensFlare;
		half4 _LensFlareColor;
		half _LensDirtIntensity;

		//Lens Dirt
		sampler2D _LensBlur, _LensDirt;

		//Image settings
		half _Brightness;
		half _Contrast;
		half _Saturation;
		sampler2D _LUTexture;
		half _ColorGradingMult;

		//Glitch
		half _FilterRadius;
		half _Flip_up, _Flip_down;
		half _Displace;
		sampler2D _GlitchTex;

		struct v2f_Simple
		{
			float4 pos	: SV_POSITION;
			half2 uv	: TEXCOORD0;
		};

		//Simple copy vertex shader
		v2f_Simple vert_Copy(appdata_img v)
		{
			v2f_Simple o;
			UNITY_INITIALIZE_OUTPUT(v2f_Simple, o);

			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord;
			/*
			#if !UNITY_UV_STARTS_AT_TOP				
				o.uv.y = 1 - o.uv.y;
			#endif

			float hpcX = 0.5 / _MainTex_TexelSize.x;
			float hpcY = 0.5 / _MainTex_TexelSize.y;
			#ifdef UNITY_HALF_TEXEL_OFFSET
				float hpcOX = -0.5;
				float hpcOY = 0.5;
			#else
				float hpcOX = 0;
				float hpcOY = 0;
			#endif	
				// Snap
			float pos = floor((o.pos.x / o.pos.w) * hpcX + 0.5f) + hpcOX;
			o.pos.x = pos / hpcX * o.pos.w;

			pos = floor((o.pos.y / o.pos.w) * hpcY + 0.5f) + hpcOY;
			o.pos.y = pos / hpcY * o.pos.w;
			*/
			
			return o;
		}

		half4 frag_Copy(v2f_Simple IN) : COLOR0
		{
			return tex2D(_MainTex, IN.uv);
		}


		inline half3 CalculateColorGrading(half3 color)
		{
			float2 Offset = float2(0.5f / 256.0f, 0.5f / 16.0f);
			float Scale = 15.0f / 16.0f; 

			float IntB = floor(color.b * 14.9999f) / 16.0f;
			half FracB = color.b * 15.0f - IntB * 16.0f;

			float U = IntB + color.r * Scale / 16.0f;
			float V = color.g * Scale;

			half3 RG0 = tex2D(_LUTexture, Offset + float2(U             , 1 - V)).rgb;
			half3 RG1 = tex2D(_LUTexture, Offset + float2(U + 1.0f / 16.0f, 1 - V)).rgb;


			return lerp(RG0, RG1, FracB);
		}

		sampler2D _LargeBloom;
		sampler2D _HeatLookup;

		half _Scale;
		half4 _AbberAmplitude;
		half4 _NoiseUV;
		sampler2D _Noise;


		
		struct v2f_Composite
		{
			float4 pos	: SV_POSITION;
			half2 uv	: TEXCOORD0;
			half2 uv1	: TEXCOORD1;
			half2 uv2	: TEXCOORD2;
			half2 uv3	: TEXCOORD3;
			half2 uv4	: TEXCOORD4;
			half2 uv5	: TEXCOORD5;
		};

		//Composite pass vertex shader
		v2f_Composite vert_Composite(appdata_img v)
		{
			v2f_Composite o;
			UNITY_INITIALIZE_OUTPUT(v2f_Composite, o);

			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord;
			o.uv1 = v.texcoord;

			#if HACKED
			if(o.uv.y < _Flip_up)
				o.uv.y = 1 - (o.uv.y + _Flip_up * 0.1);
			#endif	
			
			o.uv2 = o.uv1 * _Scale;
			o.uv3 = (o.uv1 + half2(0.2, 0.5)) * _Scale * 0.5;
			o.uv4 = o.uv1 * 6 + _NoiseUV.xy;					
					
			return o;
		}

		half4 _CurrentWashTime;
		sampler2D _StaticFrameTexture;
		sampler2D _LensFlareTexture;
		half _NoiseMult;
		half _GlitchInfluence;
		//Composite pass pixel shader
		half4 frag_Composite(v2f_Composite IN) : COLOR0
		{		
			
			#if HACKED
				half4 normal  = tex2D(_GlitchTex, IN.uv2);	
				half4 normal1 = tex2D(_GlitchTex, IN.uv3);			
				normal = (normal + normal1) * 0.5;
				
				IN.uv.x += (normal.r) * _Scale * 0.02 * _GlitchInfluence;
			#endif
				
				half4 finalColor = tex2D(_MainTex, IN.uv);					
				return finalColor.a;

			#if HACKED
				#if SIMPLE_MODE
					finalColor.g = lerp(finalColor.g, tex2D(_MainTex, IN.uv + _AbberAmplitude.x).g, normal.r);			
				#endif
			#endif

			#if JAMMED
				#if SIMPLE_MODE
					finalColor.g = finalColor.g * 0.0001 + tex2D(_MainTex, IN.uv + _AbberAmplitude.x).g;
					finalColor.b = finalColor.b * 0.0001 + tex2D(_MainTex, IN.uv - _AbberAmplitude.x).b;
				#else
					finalColor.r = finalColor.r * 0.0001 + tex2D(_MainTex, IN.uv + _AbberAmplitude.x).g;
					finalColor.b = finalColor.g * 0.0001 + tex2D(_MainTex, IN.uv - _AbberAmplitude.x).g;
				#endif
			#endif				
			
				
			#if NIGHTVISION || HEATVISION || FLIR || FLIR_BLACK || ENV
				finalColor.rgb *= (finalColor.a * 3 + 0.6);	
			#endif


			half3 origColor = finalColor.rgb;

			#if NIGHTVISION				
				finalColor.rgb *= half3(0.1, 0.95, 0.2);
				#if JAMMED							
					finalColor.rb += origColor.rb * _AbberAmplitude.y;				
				#endif
			#endif

			#if HEATVISION || FLIR || FLIR_BLACK			
				finalColor.rgb = lerp(half3(0.1, 0.1, 0.1), finalColor.rgb, saturate(finalColor.a * 100 + 0.4));					
			#endif

			
			#if BLOOM_ON
				 		
				#if SIMPLE_MODE	
				half4 bloom = tex2D(_Bloom, IN.uv) * _BloomParams.z;
				finalColor += bloom;	
				#else
					half lumBloom = Luminance(tex2D(_Bloom, IN.uv).rgb);
					half4 bloom = half4(lumBloom, lumBloom, lumBloom, 1) * _BloomParams.z;
					#if NIGHTVISION
						bloom.rgb += min(0.4, tex2D(_LargeBloom, IN.uv).rgb * 10) * half3(0.1, 0.95, 0.2);
						finalColor += bloom;	
					#endif
				#endif
				
					
			#endif

			#if LENS_FLARES_ON					
				finalColor.rgb += tex2D(_LensFlare, IN.uv).rgb * _LensFlareColor.rgb * _LensFlareColor.a;
			#endif

			#if LENS_DIRT_ON				
				finalColor.rgb += tex2D(_LensDirt, IN.uv).rgb * tex2D(_LensBlur, IN.uv).rgb * _LensDirtIntensity;
			#endif
						
			finalColor.rgb *= _Brightness;			
			
			#if FLIR || FLIR_BLACK	
				half lum1 = Luminance(finalColor).x;
				finalColor.rgb *= lerp(1, tex2D(_Noise, IN.uv4) * 0.5 + 0.5, (1 - lum1) * _NoiseMult);
			#endif
			
			#if NIGHTVISION	|| HEATVISION || ENV					
				finalColor.rgb *= lerp(0, tex2D(_Noise, IN.uv4) * 1.5, saturate(0.5 - finalColor.g) * _NoiseMult) + 1;				
			#endif	


			#if FLIR
				half3 lumCol = Luminance(finalColor);
				#if JAMMED		
					finalColor.rgb = origColor * _AbberAmplitude.z + half3(lumCol.x, lumCol.x, lumCol.x);
					finalColor = finalColor * 0.5;
				#else
					finalColor = lumCol.x;
				#endif

			#elif HEATVISION
				half3 lumCol = Luminance(finalColor);
				#if JAMMED	
					finalColor = (finalColor * _AbberAmplitude.w + tex2D(_HeatLookup, half2(lumCol.x, 0.5))) * 0.5;
				#else
					finalColor = tex2D(_HeatLookup, half2(lumCol.x, 0.5));
				#endif

			#elif FLIR_BLACK

				half3 lumCol = Luminance(finalColor);
				#if JAMMED					
					finalColor = 0.4 - (finalColor * _AbberAmplitude.w + lumCol.x);
				#else
					finalColor = 0.4 - lumCol.x;
				#endif

			#elif ENV
				half3 lumCol = Luminance(finalColor);
				finalColor.rgb = lerp(finalColor.rgb * half3(0.1, 0.95, 0.2), tex2D(_HeatLookup, half2(0.75, 0.5)), finalColor.a);
			#endif			

			#if COLOR_GRADING_ON
				//Perform color grading
				finalColor.rgb = lerp(finalColor.rgb, CalculateColorGrading(saturate(finalColor.rgb)), _ColorGradingMult);
			#endif

			#if STUN_ON
				finalColor.rgb = lerp(finalColor.rgb, tex2D(_StaticFrameTexture, IN.uv1).rgb, saturate(_CurrentWashTime.y * _CurrentWashTime.y * 2));						
				//finalColor.rgb = lerp(finalColor.rgb, half3(2, 2, 2), _CurrentWashTime.x * tex2D(_LensFlareTexture, IN.uv1 * 0.5 + half2(0.25, 0.25)).r);
				finalColor.rgb = lerp(finalColor.rgb, half3(2, 2, 2), _CurrentWashTime.x);
			#endif
			
			//finalColor.rgb *= half3(0.8, 0.95, 0.8);
			return saturate(finalColor);
		}

		//Downsample pass
		struct v2f_Downsample
		{
			float4 pos	: SV_POSITION;
			half2 uv[4]	: TEXCOORD0;
		};

		//Downsample pass vertex shader
		v2f_Downsample vert_Downsample(appdata_img v)
		{
			v2f_Downsample o;
			UNITY_INITIALIZE_OUTPUT(v2f_Downsample, o);			
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

			o.uv[0] = v.texcoord + _MainTex_TexelSize.xy * 0.5;
			o.uv[1] = v.texcoord - _MainTex_TexelSize.xy * 0.5;
			o.uv[2] = v.texcoord + _MainTex_TexelSize.xy * half2(0.5, -0.5);
			o.uv[3] = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5, 0.5);

			return o;
		}

		//Downsample pass pixel shader
		half4 frag_Downsample(v2f_Downsample IN) : COLOR0
		{
			half4 finalColor = tex2D(_MainTex, IN.uv[0]);
			finalColor += tex2D(_MainTex, IN.uv[1]);
			finalColor += tex2D(_MainTex, IN.uv[2]);
			finalColor += tex2D(_MainTex, IN.uv[3]);

			return finalColor * 0.25;
		}

		//Bright mask vertex shader
		v2f_Simple vert_BrightMask(appdata_img v)
		{
			v2f_Simple o;
			UNITY_INITIALIZE_OUTPUT(v2f_Simple, o);

			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord;

			return o;
		}

		//Bright mask pixel shader
		half4 frag_BrightMask(v2f_Simple IN) : COLOR0
		{
			half4 outColor = tex2D(_MainTex, IN.uv);
			//half3 lum = Luminance(outColor.rgb);
			//return half4(lum, 1);
			//half finalLum = max(0, lum.x - _BloomParams.x);			
			//outColor.rgb = outColor.rgb * finalLum;			
			outColor.rgb = max(half3(0, 0, 0), outColor.rgb - half3(_BloomParams.w, _BloomParams.w, _BloomParams.w));
			//outColor.rgb *= max(0, outColor.a - _BloomParams.w);

			return outColor;
		}

		//vertical blur pass
		struct v2f_Blur
		{
			float4 pos	: SV_POSITION;
			half2 uv[7]	: TEXCOORD0;			
		};

		float4 _Offsets;

		v2f_Blur vert_Blur(appdata_img v)
		{
			v2f_Blur o;
			UNITY_INITIALIZE_OUTPUT(v2f_Blur, o);

			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv[0] = v.texcoord.xy;
			o.uv[1] = v.texcoord.xy + _Offsets.xy * half2(0.5, 0.5) * _BloomParams.xy;
			o.uv[2] = v.texcoord.xy - _Offsets.xy * half2(0.5, 0.5) * _BloomParams.xy;
			o.uv[3] = v.texcoord.xy + _Offsets.xy * _BloomParams.xy;
			o.uv[4] = v.texcoord.xy - _Offsets.xy * _BloomParams.xy;
			o.uv[5] = v.texcoord.xy + _Offsets.xy * half2(1.5, 1.5) * _BloomParams.xy;
			o.uv[6] = v.texcoord.xy - _Offsets.xy * half2(1.5, 1.5) * _BloomParams.xy;
		
			return o;
		}

		half4 frag_Blur(v2f_Blur IN) : COLOR0
		{
			half4 finalColor = tex2D(_MainTex, IN.uv[0]) * 0.142;
			finalColor += tex2D(_MainTex, IN.uv[1]) * 0.143;
			finalColor += tex2D(_MainTex, IN.uv[2]) * 0.143;
			finalColor += tex2D(_MainTex, IN.uv[3]) * 0.143;
			finalColor += tex2D(_MainTex, IN.uv[4]) * 0.143;
			finalColor += tex2D(_MainTex, IN.uv[5]) * 0.143;
			finalColor += tex2D(_MainTex, IN.uv[6]) * 0.143;

			return finalColor;
		}

	ENDCG

	SubShader
	{
		ZTest Always 
		Cull Back 
		ZWrite Off 
		Blend Off

		Fog { Mode off } 

		//0: Composite Pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Composite
			#pragma fragment frag_Composite
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma target 3.0

			#pragma multi_compile BLOOM_OFF BLOOM_ON
			//#pragma multi_compile LENS_FLARES_OFF LENS_FLARES_ON
			//#pragma multi_compile LENS_DIRT_OFF LENS_DIRT_ON
			//#pragma multi_compile COLOR_GRADING_OFF COLOR_GRADING_ON
			
			#pragma multi_compile HACK_OFF HACKED   
			#pragma multi_compile JAM_OFF JAMMED
			#pragma multi_compile STUN_OFF STUN_ON
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			

			ENDCG
		}

		//1: Downsampler Pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Downsample
			#pragma fragment frag_Downsample
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG
		}

		//2: Bright Pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_BrightMask
			#pragma fragment frag_BrightMask
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG
		}

		//3: Blur Pass based on Gaussian weights
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Blur
			#pragma fragment frag_Blur
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG
		}
		
		//4: Simple copy pixels	
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Copy
			#pragma fragment frag_Copy			
			ENDCG
		}	
	}
	Fallback Off
}
