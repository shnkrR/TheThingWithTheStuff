// Simplified Additive Particle shader. Differences from regular Additive Particle one:
// - no Tint color
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "RG/Particles/Multi" 
{
Properties 
{
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_MainTex ("Particle Texture", 2D) = "white" {}
}

SubShader 
{
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Off Lighting Off  ZWrite Off Fog { Color (0,0,0,0) }	
	ColorMask RGB
	
	Pass 
	{
		CGPROGRAM
	
		#pragma vertex vert_surf
		#pragma fragment frag_surf
		#pragma fragmentoption ARB_precision_hint_fastest
		////////#pragma multi_compile_fwdbase
                                                       
		#include "HLSLSupport.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"
		
		sampler2D _MainTex;
		float4 _MainTex_ST;
		half4 _TintColor;
		
		struct appdata_simple
		{
			float4 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
			half4 color : COLOR0;			
		};
		

		struct v2f_surf 
		{
			half4 pos : SV_POSITION;
			half2 uv_MainTex : TEXCOORD0;	
			half4 vColor : TEXCOORD1;		
		};

		v2f_surf vert_surf (appdata_simple v) 
		{
			v2f_surf o;
			UNITY_INITIALIZE_OUTPUT(v2f_surf, o);
			
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.vColor = v.color;
			
			return o;
		}
		
		half4 frag_surf(v2f_surf IN) : COLOR0
		{
			half4 finalColor = half4(0, 0, 0, 1);
			finalColor = IN.vColor * _TintColor * tex2D(_MainTex, IN.uv_MainTex).r;
			
			return finalColor;
		
		}
		
		ENDCG
	}
}
}