Shader "Hidden/UIBlur" 
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


		struct v2f_Simple
		{
			float4 pos	: SV_POSITION;
			half2 uv	: TEXCOORD0;
			half2 uv2	: TEXCOORD1;
		};

		//Composite pass vertex shader
		v2f_Simple vert_Composite(appdata_img v)
		{
			v2f_Simple o;
			UNITY_INITIALIZE_OUTPUT(v2f_Simple, o);

			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord;
			o.uv2 = v.texcoord;
			#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0.0)        		
					o.uv2.y = 1 - o.uv2.y;
			#endif
			
			return o;
		}

		half4 _BgColor;
		
		
		//Composite pass pixel shader
		half4 frag_Composite(v2f_Simple IN) : COLOR0
		{
			
			half4 finalColor = tex2D(_MainTex, IN.uv);				
					
			
			half4 bloom = tex2D(_Bloom, IN.uv2);
			//return bloom;
			bloom.rgb = lerp(bloom.rgb, _BgColor.rgb, _BgColor.a);
			finalColor.rgb = lerp(bloom.rgb, finalColor.rgb, saturate(finalColor.a * 10));
			

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


		//2: Blur Pass based on Gaussian weights
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_Blur
			#pragma fragment frag_Blur
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG
		}
		
	}
	Fallback Off
}
