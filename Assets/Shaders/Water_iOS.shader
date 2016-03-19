Shader "Custom/Water_iOS" 
{
	Properties 
	{			
		_BumpMap("Bump Map 1", 2D) = "white"{}	
		_BumpMap2("Bump Map 2", 2D) = "bump"{}							
		//_WaveScale("WaveScale", Vector) = (0, 0, 0, 0)
		//_WaveOffset("Wave Offset", Vector) = (0, 0, 0, 0)
		_WaveSpeed("Wave Spped 1 & 2", Vector) = (4, 4, -2, -2)
		_RTRMultiplier("Reflectiom Multiplier", Float) = 0.5
		_ReflDistort("Reflection Distortion Multiplier", Float) = 0
		//FogHeightStart("Fog Height Start", Float) = 0
		//FogHeightEnd("Fog Height End", Float) = 1
		
		_ColorTint("Color Tint", Color) = (1, 1, 1, 1)
		_FadeColor("Fade Color", Color) = (1, 1, 1, 1)

		_SpecMultiplier("Spec Multiplier", Float) = 1		

		_Roughness("Roughness", Range(0, 0.5)) = 0.14
		_FresnelCol("Fresnel Color", Color) = (1, 1, 1, 1)
		_HeightFogFactor("height Fog Factor", Float) = 100
		

		
	}
	SubShader 
	{
		Tags { "RenderType" = "Opaque" "Lightmode" = "Forwardbase"}	
		//Blend SrcAlpha OneMinusSrcAlpha
		LOD 100	
	
		Pass
		{			
			CGPROGRAM		
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile NO_DOF WITH_DOF
			#pragma multi_compile WORLD_SPACE VIEW_SPACE 
				

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "Include/ShaderSupport.cginc"
			#pragma multi_compile SIMPLE_MODE NIGHTVISION HEATVISION FLIR FLIR_BLACK ENV
			
			half4 _WaveScale, _WaveOffset;			

			sampler2D _ReflectionTexture;			
			sampler2D _BumpMap;		
			
			half _ReflDistort;			
			half _RTRMultiplier;
			
			half _HeightFactor;						

		

			sampler2D _MainTex;

			//Scene Saturation
			uniform half _SceneSaturation = 1;

			half _ShaderTime = 0;

			//half FogHeightStart;
			//half FogHeightEnd;

			sampler2D _LerpTex;
			half _LerpValue;
			sampler2D _BumpMap2;

			//Dissolve Params
			sampler2D _DissolveTexture;
			half _DissolveAmount;
			half4 _DissolveColor1, _DissolveColor;
			half4 _FadeColor;
			sampler2D _HeightMap;

			struct appdata 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				half4 texCoord : TEXCOORD;
			};

			struct v2f
			{
				float4 vPos				: POSITION;				
				half2 BumpUV1			: TEXCOORD0;				
				half2 BumpUV2			: TEXCOORD1;				
				half4 ScreenPos			: TEXCOORD2;				
				half3 vWorldNormal		: TEXCOORD3;
				half3 vWorldTangent		: TEXCOORD4;
				half3 vWorldBinormal	: TEXCOORD5;
				half3 vViewDir			: TEXCOORD6;								
				FOG_COLOR_COORD(0)
				PROJ_COORD(7)

			};

			half4 _BumpMap_ST;
			half4 _BumpMap2_ST;

			half4 _WaveSpeed;



			v2f vert(appdata v)
			{
				v2f o;

				float4 vWorldPos = mul(_Object2World, v.vertex);				

				o.vPos = mul(UNITY_MATRIX_VP, vWorldPos);	

				o.BumpUV1 = TRANSFORM_TEX(v.texCoord, _BumpMap) + (_ShaderTime);
				o.BumpUV2 = TRANSFORM_TEX(v.texCoord, _BumpMap2) - (_ShaderTime);

				o.ScreenPos = ComputeScreenPos(o.vPos);

				o.vWorldNormal = UnityObjectToWorldNormal(v.normal);
				o.vWorldTangent = normalize((mul(_Object2World, float4(v.tangent.xyz, 0.0))).xyz);
				o.vWorldBinormal = normalize(cross(o.vWorldNormal, o.vWorldTangent) * v.tangent.w);		
				
				//_WorldSpaceCameraPos.xyz = _WorldSpaceCameraPos.xyz * 0.4;

				o.vViewDir = (vWorldPos.xyz - _WorldSpaceCameraPos.xyz);	

				APPLY_FOG(o);
				GEN_PROJ_COORD(o);
				

				return o;
			}

			float D_Approx(half Roughness, half RoL)
			{
				float a = Roughness * Roughness;
				float a2 = a * a;
				float rcp_a2 = 1.0f / a2;
				// 0.5 / ln(2), 0.275 / ln(2)
				float c = 0.72134752 * rcp_a2 + 0.39674113;
				return rcp_a2 * exp2(c * RoL - c);
			}

			inline float phong( float3 normal, float3 viewer, float3 light, float fSpecularExponent )
			{    
				// Compute the reflection vector
				float3 reflection   = normalize( 2.0f * normal * dot( normal, light ) - light );
 
				// Compute the angle between the reflection and the viewer
				float  RdotV        = max( dot( reflection, viewer ), 0.0f );
 
				// Compute the specular 
				return pow( RdotV, fSpecularExponent );
			}

			half4 _ColorTint;
			half _SpecMultiplier;
			half _NormalMapMultiplier;
			half _Roughness;
			sampler2D _Seamless;
			sampler2D _FoamTex;
			sampler2D _WaveTex;

			half blinn_phong( in half3 normal, in half3 viewer, in half3 light, half fSpecularExponent )
			{    
			    // Compute the half vector
			    half3 half_vector = normalize(light + viewer);
			 
			    // Compute the angle between the half vector and normal
			    half  HdotN = max( 0.0f, dot( half_vector, normal ) );
			 
			    // Compute the specular colour
			    return pow( HdotN, fSpecularExponent );
			}

			half4 _FresnelCol;

			half4 frag(v2f IN) : COLOR
			{				
				half3 bump1 = UnpackNormal(tex2D(_BumpMap,  IN.BumpUV1)).rgb;				
				half3 bump2 = UnpackNormal(tex2D(_BumpMap2, IN.BumpUV2)).rgb;

				half3 bump = normalize(half3(bump1.xy + bump2.xy, bump1.z * bump2.z));									
				//bump = lerp(half3(0, 0, 1), bump, 1.2);
				//bump = lerp(half3(0, 0, 1), bump, 0.6);
				half3x3 local2WorldTranspose = half3x3((IN.vWorldTangent), (IN.vWorldBinormal), (IN.vWorldNormal));
				//bump = lerp(half3(0, 0, 1), bump, 0.2);
				half3 vNormal = normalize(mul(bump, local2WorldTranspose));	

				bump = lerp(half3(0, 0, 1), bump, 0.2);
				half3 vNormal1 = normalize(mul(bump, local2WorldTranspose));		

				
				

				float3 vRefl = (reflect(normalize(IN.vViewDir), vNormal));
				float RdotL = saturate(dot(normalize(vRefl), _WorldSpaceLightPos0.xyz));
				
				half NdotL = saturate(dot(vNormal1, _WorldSpaceLightPos0.xyz)) * 0.5 + 0.3;					
				//return NdotL;

				half3 vViewDir =  normalize(-IN.vViewDir);
				
				half specDirLight =  blinn_phong(vNormal, normalize(vViewDir/* + half3(0, -0.6, 0)*/), _WorldSpaceLightPos0.xyz/* normalize(half3(vViewDir.x, 3, -vViewDir.z))*/ , 128) * _SpecMultiplier;
				//half specDirLight = D_Approx(0.2, RdotL) * 0.03;

				float4 uv1 = IN.ScreenPos;
				uv1.xy += bump.xy * _ReflDistort;
				//uv1.y -= 10;

				half NoV = 1 - saturate(dot(vNormal, vViewDir));
				//half NoV = saturate(dot(vNormal, half3(0, 0, -1)));
				//return NoV;
				NoV = NoV * NoV;// * NoV * NoV;
				//return NoV;
				//return NoV;

				
				
				half4 reflColor1 = tex2Dproj(_ReflectionTexture, UNITY_PROJ_COORD(uv1));				
				half ReflLum = Luminance(reflColor1.rgb);				
				half4 reflColor = reflColor1 * _ColorTint * _RTRMultiplier * NdotL + NoV * 0.1 ;// /** lerp(_ColorTint * 0.4, _ColorTint * 1, saturate(NdotL)) + NoV * 0.1*/;
				//reflColor = reflColor * reflColor;
				//reflColor = reflColor * lerp(half4(1, 1, 1, 1), _FresnelCol, NoV);
				reflColor = reflColor + specDirLight * _LightColor0 * (NoV * 0.5 + 0.5);

				
				half4 colorTint = half4(reflColor.rgb * _RTRMultiplier, 1);
				//colorTint = lerp(reflColor, reflColor1, saturate(IN.fogParams.x + 0.1));							
				

				#if FLIR || FLIR_BLACK
					colorTint.rgb = lerp(colorTint.rgb, half3(0.4, 0.4, 0.4), 0.5);

					
				#endif

					half volTex = 1;
					APPLY_VOL_FOG(volTex);
					colorTint.rgb = lerp(colorTint.rgb, FogColor, saturate(IN.fogParams.x * (volTex * 0.5 + 0.8)));


#if WITH_DOF
				colorTint.a = 1;
				//colorTint.a = 1 - saturate(-((IN.depth) / 100));
#else
				colorTint.a = 0;
#endif

				
				#if NIGHTVISION
					colorTint.a = 0;
				#endif

				return colorTint;
			}		
		
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
