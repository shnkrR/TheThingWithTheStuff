Shader "Custom/TerrainAdditiveLight" 
{
	Properties 
	{
	}


	CGINCLUDE

		#include "UnityCG.cginc"
		#include "Include/ShaderSupport.cginc"
		//#include "UnityStandardUtils.cginc"
		//#include "UnityStandardInput.cginc"
		//#include "UnityStandardBRDF.cginc"
		//#include "UnityStandardCore.cginc"
			
		#include "AutoLight.cginc"
		

		struct v2f
		{
			float4 vPos					: POSITION0;			
			half3 vertexLights			: TEXCOORD1;
				
		};

		v2f vert_Terrain(appdata_full v)
		{
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f, o);

			o.vPos = mul(UNITY_MATRIX_MVP, v.vertex);		
			o.vertexLights = ShadeVertexLights(v.vertex, v.normal);
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
			return half4(IN.vertexLights, 1);
		}

	ENDCG

	SubShader 
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
		LOD 100
		Blend One One	
		ColorMask RGB	

		Pass
		{			
			
			Tags 
			{ 
				"RenderType"="Transparent" 	
				"LightMode" = "Vertex"
			}
		
			CGPROGRAM

			#pragma vertex vert_Terrain
			#pragma fragment frag_Terrain		
			
			ENDCG
		}		
	} 
	FallBack Off
}
