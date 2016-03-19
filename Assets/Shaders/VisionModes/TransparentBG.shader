Shader "Custom/TransparentBG" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1, 1, 1, 1)
	}
	SubShader 
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		//Blend SrcAlpha One
		//Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
		//LOD 80
		ColorMask A
				
		Pass
		{
			CGPROGRAM
		
			#pragma vertex vert_Laser
			#pragma fragment frag_Laser
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma multi_compile NORMAL_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK			
                                                           
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half4 _MainColor;

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv_MainTex : TEXCOORD0;
			};

			v2f vert_Laser (appdata_full v) 
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);	

				return o;
			}
			
			half4 frag_Laser(v2f IN) : COLOR0
			{
				/*half4 finalColor = tex2D(_MainTex, IN.uv_MainTex);								
				finalColor.a = finalColor.a * 10;
				return finalColor;*/
				return _MainColor;
			}
			
			ENDCG
		} 
	}	
}
