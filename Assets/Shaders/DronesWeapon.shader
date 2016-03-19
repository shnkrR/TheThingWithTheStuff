Shader "Custom/DronesWeapon" 
{
	Properties 
	{		
		_MainTex ("Albedo (RGB)", 2D)			= "white" {}		
		_Metallic("Metallic", Range(0, 1))		= 0.25
		_Roughness("Roughness", Range(0, 1))    = 0.25		
		//_NormalMap("Normal Map (RGB)", 2D)		= "bump"{}
		//_AOMap("AO Map", 2D)					= "white"{}
		_Specular("Specular", Float)			= 0.5
		_ReflMult("Reflection mult", Float)		= 1
		_SpecMult("Spec Mult", Float)			= 0.5
		_RoughnessDetailTex("Roughness Detail", 2D) = "grey"{}
		_RoughnessLow("Roughness Low", Float)	= 0
		_RoughnessHigh("Roughness High", Float) = 1		
		_Saturation("Saturation", Float)		= 0.7
		_WireframeTex("Wire frame Texture", 2D) = "black"{}
		[HDR]_WireframeColor("Wire frame Color", Color) = (1, 1, 1, 1)
		_MaskTex("Mask Texture", 2D) = "black"{}
		_MaskOffset("Mask Offset", Range(0, 1)) = 0
		
	}

	SubShader 
	{
		Tags 
		{ 
			"RenderType"="Opaque"
			"LightMode" = "ForwardBase" 
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vertMetal
			#pragma fragment fragMetal

			#pragma target 3.0

			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
			#include "UnityStandardInput.cginc"
			#include "UnityStandardBRDF.cginc"
			#include "UnityStandardCore.cginc"
			#include "AutoLight.cginc"
			
			half _Roughness;			
			sampler2D _NormalMap;
			sampler2D _AOMap;
			half _Specular;
			half4 _MainColor;

			half _SpecMult;
			sampler2D _MaskTex;
			half4 _WireframeColor;
			half _MaskOffset;

			struct v2f_Metal
			{
				float4 vPos				: SV_POSITION;
				half3 vWorldNormal		: TEXCOORD0;				
				half2 uv_MainTex		: TEXCOORD1;
				half3 vWorldPos			: TEXCOORD2;
				half3 vViewDir			: TEXCOORD3;
				half3 vSHLight			: TEXCOORD4;
				half2 uv_MaskTex		: TEXCOORD5;
				//half3 vWorldTangent		: TEXCOORD5;
				//half3 vWorldBinormal	: TEXCOORD6;		
			};

			v2f_Metal vertMetal(VertexInput v)
			{
				v2f_Metal o;
				UNITY_INITIALIZE_OUTPUT(v2f_Metal, o);

				float4 vWorldPos = mul(_Object2World, v.vertex);				
				
				o.vPos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv_MainTex = TRANSFORM_TEX(v.uv0, _MainTex);

				o.vWorldPos = vWorldPos;

				o.vWorldNormal = UnityObjectToWorldNormal(v.normal);
				//o.vWorldTangent = normalize((mul(_Object2World, float4(v.tangent.xyz, 0.0))).xyz);				
				//o.vWorldBinormal = normalize(cross(o.vWorldNormal, o.vWorldTangent) * v.tangent.w); 

				o.vViewDir = (vWorldPos - _WorldSpaceCameraPos.xyz);
				o.vSHLight = ShadeSH9(half4(o.vWorldNormal, 1.0));

				//o.uv_MaskTex = half2(v.uv0.x, v.vertex.z * 0.15 - sin(_Time.y * 0.2));
				o.uv_MaskTex = half2(v.vertex.y * 0.05 + _MaskOffset, v.vertex.z * 0.05 + _MaskOffset);

				//We need this for shadow receving
				TRANSFER_SHADOW(o);

				return o;
			}

			half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
			{
				// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
				// Adaptation to fit our G term.
				const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
				const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
				half4 r = Roughness * c0 + c1;
				half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
				half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

				return SpecularColor * AB.x + AB.y;
			}

			half _ReflMult;
			#define PI 3.14159
			float GGXSpec (half NdotH, half roughness)
			{
				float a = roughness * roughness;
				float a2 = a * a;
				float d = NdotH * NdotH * (a2 - 1.f) + 1.f;
				return a2 / (PI * d * d);
			}

			float D_GGX( half Roughness, half RoL, half NoH )
			{
				float ggx = GGXSpec(NoH, Roughness);
				return ggx;
			}

			sampler2D _RoughnessDetailTex;
			sampler2D	_DetailMap;
			half _RoughnessHigh, _RoughnessLow;
			half _Saturation;
			sampler2D _WireframeTex;

			float3 Screen (float3 cBase, float3 cBlend)
			{
				return (1 - (1 - cBase) * (1 - cBlend));
			}

			half4 fragMetal(v2f_Metal IN) : COLOR0
			{
				half4 finalColor = tex2D(_MainTex, IN.uv_MainTex);
				half AO = finalColor.a;		

				
				
				//return AO;
				half3 baseColor = finalColor.rgb;
				//return half4(baseColor, 1);

				half lumBase = Luminance(baseColor);
				baseColor = lerp(half3(lumBase, lumBase, lumBase), baseColor, _Saturation);				

				half roughness = tex2D(_RoughnessDetailTex, IN.uv_MainTex * 2).r;
				roughness = roughness * roughness * 2;
				
				


				roughness = saturate(lerp(_RoughnessLow, _RoughnessHigh, roughness));

				

				
								
				half dielectricSpecular = 0.08 * _Specular;
				half3 diffuseColor	= baseColor - baseColor * _Metallic;
				half3 specularColor = (dielectricSpecular - dielectricSpecular * _Metallic) + baseColor * _Metallic;	
				

				
				

				//Sample normal map
				/*half3 vNormal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
				vNormal = lerp(half3(0, 0, 1), vNormal, 0.6);
				
				half3x3 local2WorldTranspose = half3x3((IN.vWorldTangent), (IN.vWorldBinormal), (IN.vWorldNormal));				
				vNormal = normalize(mul(vNormal, local2WorldTranspose));*/

				half3 vNormal = normalize(IN.vWorldNormal);

				half3 vViewDir = normalize(-IN.vViewDir);

				half NdotV = max(dot(vNormal, vViewDir), 0);				
				half3 vRefl = (reflect(IN.vViewDir, vNormal));

				//specularColor = EnvBRDFApprox(specularColor, roughness * roughness, NdotV);												

				//NdotV = 1 - NdotV;
				//specularColor += NdotV * NdotV * specularColor;
				
				half3 env = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, vRefl, roughness * roughness);				
				
				half lumEnv = Luminance(env);

				

				//env = lumEnv;// * lumEnv;

				
				float RdotL = saturate(dot(normalize(vRefl), _WorldSpaceLightPos0.xyz));			
				
				//roughness = lerp(0.1, 0.7, roughness) * 1.2;

				half3 halfVec = normalize (_WorldSpaceLightPos0.xyz + vViewDir);
				half NdotH = saturate(dot(vNormal, halfVec));	
				
				half3 specDirLight = D_GGX(roughness, RdotL, NdotH ) * _Metallic * specularColor;				
				
				
				specularColor = env * specularColor;

				half mask = tex2D(_MaskTex, IN.uv_MaskTex).r;				
				//return mask;

				half wireframe = tex2D(_WireframeTex, half2(0.1, IN.uv_MainTex.y * 5)).r;						
				

								
				half NdotL = saturate(dot(vNormal, _WorldSpaceLightPos0.xyz));				

				half3 ambientColor = IN.vSHLight * diffuseColor;
				diffuseColor = NdotL * _LightColor0.rgb * diffuseColor;

				finalColor.rgb = ambientColor + diffuseColor + specularColor * _ReflMult + specDirLight * _SpecMult;		

				finalColor.rgb += wireframe * _WireframeColor * mask;

				finalColor.rgb *= AO;	

					
			
				
				finalColor.a = 1;
				return finalColor;
			}

			ENDCG
		}			
	}
	
	FallBack "Diffuse"
}
