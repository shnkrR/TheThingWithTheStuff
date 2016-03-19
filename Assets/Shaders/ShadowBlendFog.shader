// WarFX Shader
// (c) 2012 Jean Moreno

Shader "Custom/ShadowBlendWithFog"
{
	Properties
	{
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Texture", 2D) = "white" {}
		_HeightFogFactor("height Fog Factor", Float) = 100
	}
	
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off Lighting Off ZWrite Off
		ColorMask RGB
		
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile WORLD_SPACE VIEW_SPACE 
			
			#include "UnityCG.cginc"
			#include "Include/ShaderSupport.cginc"
			
			#pragma debug
			
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
				
				FOG_COORD(1)
				PROJ_COORD(2)
			};
			
			struct vdata
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
//				float3 normal : NORMAL;
//    			float4 texcoord : TEXCOORD0;
//			    float4 texcoord1 : TEXCOORD1;
			    fixed4 color : COLOR;
			};
			
			fixed4 _TintColor;
			sampler2D _MainTex;
			
			v2f vert (vdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.color = v.color;
				o.uv = v.texcoord;
				
				APPLY_FOG(o);
				GEN_PROJ_COORD(o);
				
				return o;
			}
			
			fixed4 frag (v2f IN) : COLOR0
			{
				half cloudShadow1 = 0;
				APPLY_VOL_FOG(cloudShadow1);
//				return tex2D(_MainTex, i.uv) * i.color;
				fixed4 tex = tex2D(_MainTex, IN.uv);
				tex.rgb *= IN.color.rgb * _TintColor.rgb;
				//tex.rgb = lerp(fixed3(0.5,0.5,0.5), tex.rgb, tex.a * IN.color.a);		
				//return half4(FOG_FACTOR, FOG_FACTOR, FOG_FACTOR, 1);
				//tex.rgb = lerp(tex.rgb, half3(1, 1, 1), FOG_FACTOR);
				tex.a = lerp(tex.a * 0.7, 0, FOG_FACTOR * saturate(cloudShadow1 * 0.5 + 0.8));
				//tex.a = tex.a;
				//tex.rgb = lerp(fixed3(0.5,0.5,0.5), tex.rgb, tex.a * IN.color.a);
				return tex;
//				return lerp(fixed4(1,1,1,1), i.color * tex, i.color.a);
			}
			
			ENDCG
		}
	}
}