Shader "Hidden/PostProcessMat" 
{
	Properties 
	{
		_MainTex("Base", 2D) = "" {}
	}

	CGINCLUDE

		#include "UnityCG.cginc"
		#include "HLSLSupport.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"


		sampler2D _MainTex;
		float4 _MainTex_TexelSize;

		//Bloom params
		//.x - Threshold
		//.y - Blur Amount
		//.z - Bloom Multiplier
		half4 _BloomParams;		
		sampler2D _Bloom;
		sampler2D _Bloom2;
		half4 _BloomColor;

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

		//DOF Params
		half4 _DOFParameter;
		sampler2D _DOFTexture;

		//God rays params
		half4 _ScreenLightPos;
		//God rays params
		//.x - Exposure
		//.y - Decay
		//.z - Weight
		//.w - Density
		half4 _GodRaysParams;
		sampler2D _GodRaysOutput;

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
			
			//o.uv.y = 1 - o.uv.y;
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

		half _Scale;
		struct v2f_Composite
		{
			float4 pos			: SV_POSITION;
			half2 uv			: TEXCOORD0;	
			half2 uvNoise		: TEXCOORD1;	
			half2 uv1			: TEXCOORD2;
			half2 uv2			: TEXCOORD3;
		};


		float4x4 _CausticsProjMatrix;
		half4 _NoiseUV;
		
		half _Flip_up;

		//Composite pass vertex shader
		v2f_Composite vert_Composite(appdata_img v)
		{
			v2f_Composite o;
			UNITY_INITIALIZE_OUTPUT(v2f_Composite, o);

			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord;
			o.uvNoise = o.uv * 6 + _NoiseUV.xy;	

			
			o.uv1 = v.texcoord * 3;
#if GLITCH_ON
			if(o.uv.y < _Flip_up)
				o.uv.y = 1 - (o.uv.y + _Flip_up * 0.1);
#endif

			o.uv2 = o.uv1 * _Scale;

			return o;
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

		float3 Uncharted2Tonemap(float3 x)
		{
		float A = 0.15;
			float B = 0.50;
			float C = 0.10;
			float D = 0.20;
			float E = 0.02;
			float F = 0.30;
			float W = 11.2;			
			

			return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
		}

		sampler2D _DofBlurTexture;
		sampler2D _FinalRenderTexture;

		half2 CausticDistortDomainFn(half2 pos)
		{
			pos.x*=(pos.y * 0.20 + 0.5);
			pos.x*=1.0+sin(_Time.y)/10.0;
			return pos;
		}

		float CausticPatternFn(half2 pos)
		{
		half time = _Time.y;
		return (sin(pos.x*20.0+time)
		+(sin(-pos.x*50.0+time))
		/*+(sin(pos.x*30.0+time))
		+(sin(pos.x*50.0+time))
		+(sin(pos.x*80.0+time))
		+(sin(pos.x*90.0+time))
		+(sin(pos.x*12.0+time))
		+(sin(pos.x*6.0+time))
		+(sin(-pos.x*13.0+time))*/)/2.0;
		}
		

		sampler2D _WaterVolume, _OnScreenCaustics;
		half3 _CausticsOffset;
		half4 WaterVolumeColor;
		half4 _MoodColor;
		half _NVBrightness;
		sampler2D _LargeBloom;
		sampler2D _FilmNoiseTex;
		half _NoiseMult;
		sampler2D _HeatLookup;

		half4 frag_CompositePause(v2f_Composite IN) : COLOR0
		{
			return tex2D(_MainTex, IN.uv);
		}

		sampler2D _GlitchTex;
		half  _GlitchInfluence;
		half4 _AbberAmplitude;

		half4 frag_CompositeVision(v2f_Composite IN) : COLOR0
		{
#if GLITCH_ON
			half normal  = 1 - tex2D(_GlitchTex, IN.uv1);	
			half normal1 = 1 - tex2D(_GlitchTex, IN.uv2);			
			normal = (normal + normal1) * 0.5;				
			IN.uv.x += (normal.r) * _Scale * _GlitchInfluence * 0.04;
#endif
		//return tex2D(_Bloom, IN.uv);
			half4 srcColor = tex2D(_MainTex, IN.uv);
			//srcColor.rgb *= (srcColor.a * 3 + 0.6);				

			half4 finalColor = srcColor;	

			#if JAMMED
				finalColor.g = finalColor.g * 0.0001 + tex2D(_MainTex, IN.uv + _AbberAmplitude.y).g;
				finalColor.b = finalColor.b * 0.0001 + tex2D(_MainTex, IN.uv - _AbberAmplitude.x * 2).b;
			#endif					


			#if NIGHTVISION			
				finalColor.rgb += tex2D(_Bloom, IN.uv) * 5  + min(0.4, tex2D(_LargeBloom, IN.uv) * 10);
				finalColor.rgb = finalColor.rgb * half3(0.1, 0.5, 0.2) *  _Brightness;			
			#endif

			#if FLIR
				finalColor.rgb *= (finalColor.a * 3 + 1) * _Brightness;	
				//finalColor.rgb = lerp(finalColor.rgb, tex2D(_Bloom, IN.uv), 0.2);
				half3 lumCol = Luminance(finalColor);
				finalColor = lumCol.x;
			#endif

			#if FLIR_BLACK
				finalColor.rgb *= (finalColor.a * 3 + 0.6) * _Brightness;	
				half3 lumCol = Luminance(finalColor);
				finalColor = saturate(0.4 - lumCol.x) * 2;
			#endif

			#if HEATVISION				
				finalColor.rgb = lerp(half3(0.2, 0.2, 0.2), finalColor.rgb, saturate(finalColor.a * 100 + 0.2));		
				half3 lumCol = Luminance(finalColor);
				finalColor = tex2D(_HeatLookup, half2(lumCol.x, 0.5)) * _Brightness;
			#endif

			#if ENV
				half3 lumCol = Luminance(finalColor);
				finalColor.rgb += tex2D(_Bloom, IN.uv) * 2  + min(0.4, tex2D(_LargeBloom, IN.uv));
				//finalColor.rgb = lerp(half3(0.2, 0.2, 0.2), finalColor.rgb, saturate(finalColor.a * 100 + 0.7));		
				
				finalColor.rgb = lerp(finalColor.rgb * half3(0.1, 0.95, 0.2), tex2D(_HeatLookup, half2(lumCol.x, 0.5)), saturate(finalColor.a * 100)) * _Brightness;
			#endif	

			#if FILM_GRAIN_ON
				half lum1 = Luminance(finalColor).x;
				finalColor.rgb *= lerp(1, tex2D(_FilmNoiseTex, IN.uvNoise).r * 0.5 + 0.5, (1 - lum1) * _NoiseMult);
			#endif

			return finalColor;
		}

		
		//Composite pass pixel shader
		half4 frag_Composite(v2f_Composite IN) : COLOR0
		{/*
			half2 waterDistortion = UnpackNormal(tex2D(_WaterVolume, IN.uv + half2(_Time.x, _Time.x) * 2) ).xy;
			IN.uv += waterDistortion * 0.007;*/	
							
			/*half caustics = tex2D(_OnScreenCaustics, (IN.uv * half2(0.25, 0.25) * half2(1.5, 0.2) + half2(-IN.uv.y * 0.1 * _CausticsOffset.z, 0) + _CausticsOffset.xy * half2(0.25, 0.25)));
			caustics = caustics + tex2D(_OnScreenCaustics, (IN.uv * half2(0.25, 0.25) * half2(1.5, 0.2) + half2(-IN.uv.y * 0.1 * _CausticsOffset.z, 0) + half2(0.5, 0.5) + _CausticsOffset.xy * half2(0.25, 0.25)));
			
			//return caustics;

			//caustics = caustics + tex2D(_OnScreenCaustics, (IN.uv * half2(0.25, 0.25) * half2(1.5, 0.2 * _CausticsOffset.z) + half2(0.2, 0.3) + _CausticsOffset.xy * half2(0.25, 0.25)));;
			caustics = caustics * IN.uv.y;		

				*/		
			//return caustics;
			//return tex2D(_Bloom, IN.uv);

#if GLITCH_ON
			half normal  = tex2D(_GlitchTex, IN.uv1);	

			//return normal;

			half normal1 = tex2D(_GlitchTex, IN.uv2);			
			normal = (normal + normal1) * 0.5;				
			IN.uv.x += (normal.r) * _Scale * _GlitchInfluence * 0.04;
#endif

			//return _Scale;

			half4 finalColor = tex2D(_MainTex, IN.uv);	

			
			#if JAMMED
				finalColor.g = finalColor.g * 0.0001 + tex2D(_MainTex, IN.uv + _AbberAmplitude.y).g;
				finalColor.b = finalColor.b * 0.0001 + tex2D(_MainTex, IN.uv - _AbberAmplitude.x * 2).b;
			#endif					

			
			half depth = finalColor.a;
			
			
			
			//return tex2D(_FinalRenderTexture, IN.uv) * 2;
			#if BLOOM_ON	
				half4 bloom = tex2D(_Bloom, IN.uv) * _BloomParams.z * _BloomColor;			
				finalColor *= (1 - saturate(bloom));
				finalColor += bloom;		
			#endif

			#if DOF_ON				
					half4 bokeh = tex2D(_DOFTexture, IN.uv) * 0.85;					
					half dofFactor = smoothstep(0.25, 1, (1 - depth + _DOFParameter.x) * _DOFParameter.y);				
					//return dofFactor;
					
					finalColor = lerp(finalColor, bokeh, dofFactor);				
			#endif //WITH_DOF

			#if LENS_FLARES_ON	
				//return tex2D(_LensFlare, IN.uv) * _LensFlareColor * _LensFlareColor.a;			
				finalColor.rgb += tex2D(_LensFlare, IN.uv).rgb * _LensFlareColor.rgb * _LensFlareColor.a * 10;
			#endif

			

			#if GODRAYS_ON
				half godRays = tex2D(_GodRaysOutput, IN.uv).r;								
				//return godRays;
				
				godRays = godRays * godRays * 1.5;
				finalColor.rgb += godRays;// * _LightColor0.rgb;				
			#endif

			
			
			

			//finalColor.rgb = finalColor.rgb / (half3(1, 1, 1) - (Luminance(finalColor.rgb).r / 50));
			//finalColor.rgb *= 4;
			
			
			/*half3 cMood = lerp(half3(0, 0, 0), _MoodColor.rgb, saturate(fLumFinalColor.x * 2));
			cMood = lerp(cMood, 1, saturate(fLumFinalColor.x - 0.5) * 2);
			finalColor.rgb = lerp(finalColor.rgb, cMood.rgb, saturate(fLumFinalColor.x * _MoodColor.a));
			*/
			finalColor.rgb = max(half3(0, 0, 0), lerp(finalColor.rgb, finalColor.rgb * finalColor.rgb, _Contrast));
			//finalColor.rgb = pow(finalColor.rgb, _Contrast);
			finalColor.rgb *= _Brightness;
			finalColor.rgb = lerp(finalColor.rgb, finalColor.rgb * _MoodColor.rgb, _MoodColor.a);
			half3 fLumFinalColor = saturate(Luminance(finalColor.rgb));

			

			//return fLumFinalColor.r * fLumFinalColor.r - 1;
			finalColor.rgb = lerp(fLumFinalColor, finalColor.rgb, _Saturation);

			#if FILM_GRAIN_ON
				//half lum1 = Luminance(finalColor).x;
				finalColor.rgb *= lerp(1, tex2D(_FilmNoiseTex, IN.uvNoise).r * 0.5 + 0.5, (1 - fLumFinalColor.x) * _NoiseMult);
			#endif

			

			
			/*float A = 0.15;
			float B = 0.50;
			float C = 0.10;
			float D = 0.20;
			float E = 0.02;
			float F = 0.30;
			float W = 11.2;

			float ExposureBias = 2.0f;
			float3 curr = Uncharted2Tonemap(ExposureBias*finalColor.rgb);

			float3 whiteScale = 1.0f/Uncharted2Tonemap(W);
			float3 color = curr*whiteScale;
			finalColor.rgb = color;*/
			// float3 retColor = pow(color,1/2.2);
			//return float4(color,1);
			
			//half3 x = max(half3(0, 0, 0), finalColor.rgb - 0.004);
			//half3 retColor = (x*(6.2*x+.5))/(x*(6.2*x+1.7)+0.06);
			//finalColor.rgb = retColor;

			#if COLOR_GRADING_ON
				//Perform color grading
				finalColor.rgb = lerp(finalColor.rgb, CalculateColorGrading(saturate(finalColor.rgb)), _ColorGradingMult);
			#endif

			#if LENS_DIRT_ON
				//return tex2D(_LensBlur, IN.uv);
				half3 lum = tex2D(_LensBlur, half2(1, 1) - IN.uv).rgb;
				lum.r = lum.r + lum.g + lum.b;
				half lensDirt = saturate(tex2D(_LensDirt, IN.uv).r * lum.r * _LensDirtIntensity);
				finalColor.rgb = finalColor.rgb + lensDirt;
			#endif

			
			//finalColor.rgb += (1 - fLumFinalColor) * finalColor.rgb * caustics * WaterVolumeColor.rgb * WaterVolumeColor.a * 10;

			return saturate(finalColor /** half4(0.9, 1, 0.8, 1)*/);
		}

		


		//bloom combine pass
		half4 frag_CombineBloom(v2f_Simple IN) : COLOR0
		{
			//return tex2D(_Bloom, IN.uv);
			half4 finalColor = tex2D(_MainTex, IN.uv);				
			
			#if BLOOM_ON	
				half4 bloom = tex2D(_Bloom, IN.uv) * _BloomParams.z * _BloomColor;							
				finalColor *= (1 - saturate(bloom));
				finalColor.rgb += bloom.rgb;		
			#endif
			
			//finalColor.rgb = min(finalColor.rgb, half3(2, 2, 2));
			return finalColor;
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

			return outColor;
		}
			
		//Bright mask pixel shader for vision modes
		half4 frag_DownBrightMaskVision(v2f_Downsample IN) : COLOR0
		{
			half4 finalColor = tex2D(_MainTex, IN.uv[0]) * 0.25;
			finalColor += tex2D(_MainTex, IN.uv[1]) * 0.25;
			finalColor += tex2D(_MainTex, IN.uv[2]) * 0.25;
			finalColor += tex2D(_MainTex, IN.uv[3]) * 0.25;	

			//half mask = saturate(3 - finalColor.a);
			finalColor.rgb *= max(0, finalColor.a * 2 * saturate(1 - finalColor.a));

			return finalColor;
		}

		//Downsample with brightpass vertex shader		
		v2f_Downsample vert_DownBrightPass(appdata_img v)
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

		//Downsample with brightpass pixel shader		
		half4 frag_DownBrightPass(v2f_Downsample IN) : COLOR0
		{
			half4 finalColor = tex2D(_MainTex, IN.uv[0]) * 0.25;
			finalColor += tex2D(_MainTex, IN.uv[1]) * 0.25;
			finalColor += tex2D(_MainTex, IN.uv[2]) * 0.25;
			finalColor += tex2D(_MainTex, IN.uv[3]) * 0.25;

			//finalColor *= 0.25;
			half lum = Luminance(finalColor);
			half finalLum = max(0, lum - _BloomParams.w);
			finalColor.rgb = finalColor.rgb * finalLum / lum;
			//finalColor.rgb = initColor.rgb * initColor.a * 5;
			//finalColor.rgb *= max(0, finalColor.a * 2);

			return finalColor;
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

		//vertical blur pass
		struct v2f_OptBlur
		{
			float4 pos	: SV_POSITION;
			half2 uv[5]	: TEXCOORD0;			
		};

		v2f_OptBlur vert_BlurUp(appdata_img v)
		{
			v2f_OptBlur o;
			UNITY_INITIALIZE_OUTPUT(v2f_OptBlur, o);
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

			o.uv[0] = v.texcoord.xy;

			half temp = _DOFParameter.y;

			o.uv[1] = v.texcoord.xy - half2(0, temp * 0.5);
			o.uv[2] = v.texcoord.xy - half2(0, temp);
			o.uv[3] = v.texcoord.xy - half2(0, temp * 1.5);
			o.uv[4] = v.texcoord.xy - half2(0, temp * 2);

			return o;
		}

		#define BLUR_ADJUST 1
		half4 frag_BlurUp(v2f_OptBlur IN) : COLOR
		{	
		
		#if SMART_BLUR
			
			half4 mainColor = tex2D(_MainTex, IN.uv[0]);
			half4 color = tex2D(_MainTex,  IN.uv[1]);
			half4 outColor = mainColor;			
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));
			
			color = tex2D(_MainTex,  IN.uv[2]);			
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));			
			color = tex2D(_MainTex,  IN.uv[3]);			
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));
			
			color = tex2D(_MainTex,  IN.uv[4]);			
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));
			
		#else
			
			half4 outColor = tex2D(_MainTex, IN.uv[0]);
							
			outColor += tex2D(_MainTex, IN.uv[1]);
			outColor += tex2D(_MainTex, IN.uv[2]);
			outColor += tex2D(_MainTex, IN.uv[3]);
			outColor += tex2D(_MainTex, IN.uv[4]);

		#endif

			

			return outColor * 0.2;
		}

		v2f_OptBlur vert_BlurLeftDown(appdata_img v)
		{
			v2f_OptBlur o;
			UNITY_INITIALIZE_OUTPUT(v2f_OptBlur, o);
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

			o.uv[0] = v.texcoord.xy;

			half tempX = _DOFParameter.x;
			half tempY = _DOFParameter.y * 0.5;

			o.uv[1] = v.texcoord.xy + half2(tempX * 0.5,  tempY * 0.5);
			o.uv[2] = v.texcoord.xy + half2(tempX,		 tempY);
			o.uv[3] = v.texcoord.xy + half2(tempX * 1.5,	 tempY * 1.5);
			o.uv[4] = v.texcoord.xy + half2(tempX * 2,	 tempY * 2);

			return o;
		}

		sampler2D _VertBlurRT;

		half4 frag_BlurLeftDown(v2f_OptBlur IN) : COLOR
		{
		#if SMART_BLUR	

			half4 mainColor = tex2D(_MainTex, IN.uv[0]);
			half4 color = tex2D(_MainTex,  IN.uv[1]);
						
			half4 outColor = mainColor;
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));

			color = tex2D(_MainTex,  IN.uv[2]);
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));

			color = tex2D(_MainTex,  IN.uv[3]);
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));

			color = tex2D(_MainTex,  IN.uv[4]);
			outColor += lerp(color, mainColor, saturate((color.a - mainColor.a) * BLUR_ADJUST));			

		#else
					
			half4 outColor = tex2D(_MainTex, IN.uv[1]);
			outColor += tex2D(_MainTex, IN.uv[2]);
			outColor += tex2D(_MainTex, IN.uv[3]);
			outColor += tex2D(_MainTex, IN.uv[4]);

		#endif

			return (outColor * 0.25 + tex2D(_VertBlurRT, IN.uv[0])) * 0.5;	
		}

		struct v2f_FinalBokeh
		{
			float4 pos : POSITION0;
			half2 uv[7] : TEXCOORD0;			
			half4 uv1	: TEXCOORD7;
		};

		v2f_FinalBokeh vert_FinalBokeh(appdata_img v)
		{
			v2f_FinalBokeh o;
			UNITY_INITIALIZE_OUTPUT(v2f_FinalBokeh, o);
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			//o.uv = v.texcoord.xy;

			half tempX = _DOFParameter.x;
			half tempY = _DOFParameter.y * 0.5;

			//Bottom color uvs
			o.uv[0] = v.texcoord.xy - half2(tempX * 0.5, -tempY * 0.5);
			o.uv[1] = v.texcoord.xy - half2(tempX,       -tempY);
			o.uv[2] = v.texcoord.xy - half2(tempX * 1.5, -tempY * 1.5);
			o.uv[3] = v.texcoord.xy - half2(tempX * 2,   -tempY * 2);

			//Top color uvs
			o.uv[4] = v.texcoord.xy + half2(tempX * 0.5, tempY * 0.5);
			o.uv[5] = v.texcoord.xy + half2(tempX,       tempY);
			o.uv[6] = v.texcoord.xy + half2(tempX * 1.5, tempY * 1.5);
			o.uv1.xy = v.texcoord.xy + half2(tempX * 2,   tempY * 2);
			o.uv1.zw = v.texcoord.xy;



			return o;
		}

		
		half4 frag_FinalBokeh(v2f_FinalBokeh IN) : COLOR
		{
			
			#if SMART_BLUR				
				
				half tempX = _DOFParameter.x;
				half tempY = _DOFParameter.y * 0.5;
			
				half4 mainColor = tex2D(_MainTex, IN.uv[0]);
				half4 color = tex2D(_MainTex, IN.uv[1]);
				half4 bottomColor = mainColor;
				bottomColor += lerp(color, mainColor, saturate((color.a - mainColor.a)));		

				color = tex2D(_MainTex, IN.uv[2]);
				bottomColor += lerp(color, mainColor, saturate((color.a - mainColor.a)));		
			
				color = tex2D(_MainTex, IN.uv[3]);
				bottomColor += lerp(color, mainColor, saturate((color.a - mainColor.a)));	
			

				mainColor = tex2D(_VertBlurRT, IN.uv1.zw);	
				color = tex2D(_VertBlurRT, IN.uv[4]);
				half4 topColor = mainColor;
				topColor += lerp(color, mainColor, saturate((color.a - mainColor.a)));

				color = tex2D(_VertBlurRT, IN.uv[5]);
				topColor += lerp(color, mainColor, saturate((color.a - mainColor.a)));

				color = tex2D(_VertBlurRT, IN.uv[6]);
				topColor += lerp(color, mainColor, saturate((color.a - mainColor.a)));

				color = tex2D(_VertBlurRT, IN.uv1.xy);
				topColor += lerp(color, mainColor, saturate((color.a - mainColor.a)));

				return (bottomColor * 0.25 + topColor * 0.1) * 0.8;

			#else

				half tempX = _DOFParameter.x;
				half tempY = _DOFParameter.y * 0.5;
			
				half4 bottomColor = tex2D(_MainTex, IN.uv[0]);
				bottomColor += tex2D(_MainTex, IN.uv[1]);		
				bottomColor += tex2D(_MainTex, IN.uv[2]);
				bottomColor += tex2D(_MainTex, IN.uv[3]);
			

				half4 topColor = tex2D(_VertBlurRT, IN.uv1.zw);			
			
			
				topColor += tex2D(_VertBlurRT, IN.uv[4]);
				topColor += tex2D(_VertBlurRT, IN.uv[5]);			
				topColor += tex2D(_VertBlurRT, IN.uv[6]);
				topColor += tex2D(_VertBlurRT, IN.uv1.xy);
			

				return (bottomColor * 0.25 + topColor * 0.1) * 0.8;

			#endif		

		}

		//God Rays pass
#define SUN_P0 (31.0/32.0)
#define SUN_P1 (27.0/32.0)
#define SUN_P2 (23.0/32.0)
#define SUN_P3 (19.0/32.0)
#define SUN_P4 (15.0/32.0)
#define SUN_P5 (11.0/32.0)
#define SUN_P6 (7.0/32.0)

#define MULTIPLIER 1.0

		//God rays params
		//.x - Exposure
		//.y - Decay
		//.z - Weight
		//.w - Density

		float2 SunShaftRect(float2 InPosition, float amount) 
		{			
			//half4 screenLightPos = mul(UNITY_MATRIX_VP, _WorldSpaceLightPos0);
			return lerp(_ScreenLightPos.xy, InPosition, amount);
		}

		struct v2fGodRays
		{
			float4 pos : SV_POSITION;
			float2 vTexCoord[8] : TEXCOORD0;
		};	

		v2fGodRays vert_GodRays(appdata_img v)
		{
			v2fGodRays o;
			UNITY_INITIALIZE_OUTPUT(v2fGodRays, o);
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);			

			o.vTexCoord[0] = SunShaftRect(v.texcoord.xy, 1.0 - SUN_P0 * MULTIPLIER * _GodRaysParams.w);
			o.vTexCoord[1] = SunShaftRect(v.texcoord.xy, 1.0 - SUN_P1 * MULTIPLIER * _GodRaysParams.w);
			o.vTexCoord[2] = SunShaftRect(v.texcoord.xy, 1.0 - SUN_P2 * MULTIPLIER * _GodRaysParams.w);
			o.vTexCoord[3] = SunShaftRect(v.texcoord.xy, 1.0 - SUN_P3 * MULTIPLIER * _GodRaysParams.w);
			o.vTexCoord[4] = SunShaftRect(v.texcoord.xy, 1.0 - SUN_P4 * MULTIPLIER * _GodRaysParams.w);
			o.vTexCoord[5] = SunShaftRect(v.texcoord.xy, 1.0 - SUN_P5 * MULTIPLIER * _GodRaysParams.w);
			o.vTexCoord[6] = SunShaftRect(v.texcoord.xy, 1.0 - SUN_P6 * MULTIPLIER * _GodRaysParams.w);
			o.vTexCoord[7] = v.texcoord.xy;

			return o;
		}

//#undef MULTIPLIER

		half4 frag_GodRays(v2fGodRays IN) : COLOR
		{
			half4 finalColor = half4(0, 0, 0, 0);

			finalColor.r =	tex2D(_MainTex, IN.vTexCoord[0]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[1]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[2]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[3]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[4]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[5]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[6]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[7]).r * 0.125 * _GodRaysParams.z;			

			//finalColor.r = HighlightCompression(finalColor.r);
			finalColor = finalColor * _GodRaysParams.x;

			return finalColor;
		}

		v2fGodRays vert_GodRaysSec(appdata_img v)
		{
			v2fGodRays o;
			UNITY_INITIALIZE_OUTPUT(v2fGodRays, o);

			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			half2 deltaTexCoord = (v.texcoord - _ScreenLightPos.xy) * _GodRaysParams.w * MULTIPLIER / 8 ;
			o.vTexCoord[0] = v.texcoord;
			o.vTexCoord[1] = o.vTexCoord[0] - deltaTexCoord;
			o.vTexCoord[2] = o.vTexCoord[1] - deltaTexCoord;
			o.vTexCoord[3] = o.vTexCoord[2] - deltaTexCoord;
			o.vTexCoord[4] = o.vTexCoord[3] - deltaTexCoord;
			o.vTexCoord[5] = o.vTexCoord[4] - deltaTexCoord;
			o.vTexCoord[6] = o.vTexCoord[5] - deltaTexCoord;
			o.vTexCoord[7] = o.vTexCoord[6] - deltaTexCoord;

			return o;
		}

		half4 frag_GodRaysSec(v2fGodRays IN) : COLOR
		{
			half4 finalColor = half4(0, 0, 0, 0);

			finalColor.r =	tex2D(_MainTex, IN.vTexCoord[0]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[1]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[2]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[3]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[4]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[5]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[6]).r * 0.125 * _GodRaysParams.z +
							tex2D(_MainTex, IN.vTexCoord[7]).r * 0.125 * _GodRaysParams.z;			

			//finalColor.r = HighlightCompression(finalColor.r);
			finalColor = finalColor * _GodRaysParams.x;
	
			return finalColor;
		}


		v2f_Simple vert_GodRaysMask(appdata_img v)
		{
			v2f_Simple o;
			UNITY_INITIALIZE_OUTPUT(v2f_Simple, o);
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;

			return o;
		}

		half4 frag_GodRaysMask(v2f_Simple IN) : COLOR0
		{
			//return tex2D(_MainTex, IN.uv);
			half4 finalColor = tex2D(_MainTex, IN.uv);						
			return saturate(1 - finalColor.a * 2);
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
			#pragma multi_compile LENS_FLARES_OFF LENS_FLARES_ON
			#pragma multi_compile LENS_DIRT_OFF LENS_DIRT_ON
			#pragma multi_compile COLOR_GRADING_OFF COLOR_GRADING_ON
			#pragma multi_compile DOF_OFF DOF_ON
			#pragma multi_compile GODRAYS_OFF GODRAYS_ON
			#pragma multi_compile FILM_GRAIN_ON FILM_GRAIN_OFF
			#pragma multi_compile GLITCH_OFF GLITCH_ON
			#pragma multi_compile JAMMED_OFF JAMMED

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

		//5: Combine bloom with base texture
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Composite
			#pragma fragment frag_CombineBloom
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma multi_compile BLOOM_OFF BLOOM_ON
			ENDCG
		}	

		//6: Up blur pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_BlurUp
			#pragma fragment frag_BlurUp
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile SIMPLE_BLUR SMART_BLUR
			ENDCG
		}	

		//7: Left down pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_BlurLeftDown
			#pragma fragment frag_BlurLeftDown
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile SIMPLE_BLUR SMART_BLUR
			ENDCG
		}	

		//8: Finalbokeh pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_FinalBokeh
			#pragma fragment frag_FinalBokeh
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile SIMPLE_BLUR SMART_BLUR	
			ENDCG
		}	

		//9: Downscale with bright pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_DownBrightPass
			#pragma fragment frag_DownBrightPass
			#pragma fragmentoption ARB_precision_hint_fastest		
			ENDCG
		}

		//10: God rays pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_GodRays
			#pragma fragment frag_GodRays
			#pragma fragmentoption ARB_precision_hint_fastest		
			ENDCG
		}

		//11: God rays second pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_GodRaysSec
			#pragma fragment frag_GodRaysSec
			#pragma fragmentoption ARB_precision_hint_fastest		
			ENDCG
		}

		//12: God rays mask
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_GodRaysMask
			#pragma fragment frag_GodRaysMask
			#pragma fragmentoption ARB_precision_hint_fastest		
			ENDCG
		}

		//13: Night vision bright Pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_DownBrightPass
			#pragma fragment frag_DownBrightMaskVision
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG
		}

		//14: Vision mode composite
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Composite
			#pragma fragment frag_CompositeVision
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV		
			#pragma multi_compile FILM_GRAIN_ON FILM_GRAIN_OFF
			#pragma multi_compile GLITCH_OFF GLITCH_ON
			#pragma multi_compile JAMMED_OFF JAMMED

			ENDCG
		}

		//15: Pause composite
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Composite
			#pragma fragment frag_CompositePause
			#pragma fragmentoption ARB_precision_hint_fastest	
			ENDCG
		}
			
	}
	Fallback Off
}
