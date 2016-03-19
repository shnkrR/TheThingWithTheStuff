Shader "Custom/DronesVehicles" 
{
	Properties 
	{		
		_MainTex ("Albedo (RGB)", 2D)			= "white" {}		
		[HDR]_MainColor("Main Color", Color)	= (1, 1, 1, 1)
		_Metallic("Metallic", Range(0, 1))		= 0.25
		_RoughnessLow("Roughness Low", Range(0, 1))    = 0.25		
		_RoughnessHigh("Roughness High", Range(0, 1)) = 1
		_GlassRoughness("Glass Roughness", Float) = 0.02
		_NormalMap("Normal Map (RGB)", 2D)		= "bump"{}		
		_Specular("Specular", Float)			= 0.5
		_ReflMult("Reflection mult", Float)		= 1
		_GlassReflMult("Glass Refl mult", Float) = 1
		_SpecMult("Spec Mult", Float)			= 0.5				
		_GlassMask("GlassMask", 2D)				= "black"{}
		_DirtTex("Dirt Texture", 2D)			= "white"{}
		_SpecRoughness("Spec Roughness", Float) = 0.4
		_CubeMap("Cube Map", CUBE) = "skybox"{}

		
	}

	SubShader 
	{		

		Tags 
		{ 
			"RenderType"="Opaque"
			//"LightMode" = "ForwardBase" 
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vertMetal
			#pragma fragment fragMetal

			//#pragma target 3.0

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
			sampler2D _GlassMask;
			half _GlassReflMult;
			sampler2D _DirtTex;
			

			half _SpecMult;
			half4 _VehicleColor1;

			struct v2f_Metal
			{
				float4 vPos				: SV_POSITION;
				half3 vWorldNormal		: TEXCOORD0;				
				half2 uv_MainTex		: TEXCOORD1;
				half3 vWorldPos			: TEXCOORD2;
				half3 vViewDir			: TEXCOORD3;
				half3 vSHLight			: TEXCOORD4;
				half3 vWorldTangent		: TEXCOORD5;
				half3 vWorldBinormal	: TEXCOORD6;		
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
				o.vWorldTangent = normalize((mul(_Object2World, float4(v.tangent.xyz, 0.0))).xyz);				
				o.vWorldBinormal = normalize(cross(o.vWorldNormal, o.vWorldTangent) * v.tangent.w); 

				o.vViewDir = (vWorldPos - _WorldSpaceCameraPos.xyz);
				o.vSHLight =  ShadeVertexLights(v.vertex, v.normal);

				//We need this for shadow receving
				//TRANSFER_SHADOW(o);

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
			half _GlassRoughness;
			half _SpecRoughness;
			samplerCUBE _CubeMap;

			half4 fragMetal(v2f_Metal IN) : COLOR0
			{

				half4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
				half lumTex = Luminance(mainTex);
				//mainTex.rgb = lerp(half3(lumTex, lumTex, lumTex), mainTex, 0.4);
				half4 finalColor = mainTex * _MainColor;	

				
				half3 baseColor = finalColor.rgb;				
				
				half AO = finalColor.a;		
				half glassMask = tex2D(_GlassMask, IN.uv_MainTex).r;	
				
				_Metallic = lerp(_Metallic, 1, glassMask);
								
				half dielectricSpecular = 0.08 * _Specular;
				half3 diffuseColor	= baseColor - baseColor * _Metallic;
				half3 specularColor = (dielectricSpecular - dielectricSpecular * _Metallic) + baseColor * _Metallic;	
				
				half dirtMask = tex2D(_DirtTex, IN.uv_MainTex * 10).r;
				dirtMask = dirtMask * dirtMask * 2;
				_Roughness = lerp(_RoughnessLow, _RoughnessHigh, dirtMask);

				_Roughness = saturate(lerp(_Roughness, _GlassRoughness, glassMask));
				

				//Sample normal map
				half3 vNormal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));				
				vNormal = lerp(half3(0, 0, 1), vNormal, 0.4);
				
				half3x3 local2WorldTranspose = half3x3((IN.vWorldTangent), (IN.vWorldBinormal), (IN.vWorldNormal));				
				vNormal = normalize(mul(vNormal, local2WorldTranspose));

				//half3 vNormal = normalize(IN.vWorldNormal);

				half3 vViewDir = normalize(-IN.vViewDir);

				half NdotV = max(dot(vNormal, vViewDir), 0);				
				half3 vRefl = (reflect(IN.vViewDir, vNormal));

				//specularColor = EnvBRDFApprox(specularColor, _Roughness, NdotV);												
				

				NdotV = 1 - NdotV;
				
				specularColor += NdotV * NdotV * specularColor;	

				half3 env = texCUBE(_CubeMap, vRefl);	
				
				//half3 env = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, vRefl, _Roughness);				
				env = lerp(env, env * env, 0.5);

				
				//float RdotL = saturate(dot(normalize(vRefl), _WorldSpaceLightPos0.xyz));			
				
				//roughness = lerp(0.1, 0.7, roughness) * 1.2;

				//half3 halfVec = normalize (_WorldSpaceLightPos0.xyz + vViewDir);
				//half NdotH = saturate(dot(vNormal, halfVec));	
				
				//half3 specDirLight = D_GGX(_SpecRoughness, RdotL, NdotH ) * specularColor;				
				
				
				env = env * specularColor;
								
				half NdotL = saturate(dot(vNormal, _WorldSpaceLightPos0.xyz));				
				//return half4(IN.vSHLight, 1);
				half3 ambientColor = IN.vSHLight * diffuseColor;
				diffuseColor = NdotL * _LightColor0.rgb * diffuseColor;

				finalColor.rgb = ambientColor + diffuseColor + env * lerp(_ReflMult, _GlassReflMult, glassMask);// + specDirLight * _SpecMult * specularColor * (1 - glassMask);		
				finalColor.rgb *= (AO * 0.9 + 0.1) * _VehicleColor1.rgb * 3;
				finalColor.a = 1;
				
				return finalColor;
			}

			ENDCG
		}			
		//UsePass "Custom/PlanarShadow/PLANARSHADOW"
	}

	
	
	FallBack "Diffuse"
}
