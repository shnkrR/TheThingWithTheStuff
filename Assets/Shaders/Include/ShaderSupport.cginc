sampler2D _FogNoise;
half4 FogColor;
half FogStart;
half FogEnd;
float4x4 _ProjMatrix;
half _WindSpeed;
half FogHeightStart;
half FogHeightEnd;
half _HeightFogFactor;
half3 _DroneAnchor;

#define FOG_COORD(x) half2 fogParams : TEXCOORD##x;
#define PROJ_COORD(x) half4 texProjCoord : TEXCOORD##x;
#define FOG_COLOR_COORD(x) half2 fogParams : COLOR##x;

#if VIEW_SPACE
	#define APPLY_FOG(o) float3 vWorldPos1 = mul(_Object2World, v.vertex).xyz; \
	half2 ViewSpaceDepth = mul(UNITY_MATRIX_MV, v.vertex).yz; \
	o.fogParams.x = saturate((FogStart + ViewSpaceDepth.y) / (FogStart - FogEnd)); \
	o.fogParams.x *= saturate((FogHeightEnd - vWorldPos1.y) * (vWorldPos1.y - FogHeightStart) / (FogHeightEnd - FogHeightStart)); \
	o.fogParams.x *= saturate(1.0f / (10 + vWorldPos1.y) * _HeightFogFactor);  \
	COMPUTE_EYEDEPTH(o.fogParams.y);
#else
	#define APPLY_FOG(o) float3 vWorldPos1 = mul(_Object2World, v.vertex).xyz; \
	half2 ViewSpaceDepth = mul(UNITY_MATRIX_MV, v.vertex).yz; \
	ViewSpaceDepth.y = length(vWorldPos1.xz - _DroneAnchor.xz) / 3; \
	o.fogParams.x = saturate((FogStart - ViewSpaceDepth.y) / (FogStart - FogEnd)); \
	o.fogParams.x *= saturate((FogHeightEnd - vWorldPos1.y) * (vWorldPos1.y - FogHeightStart) / (FogHeightEnd - FogHeightStart)); \
	o.fogParams.x *= saturate(1.0f / (10 + vWorldPos1.y) * _HeightFogFactor);  \
	COMPUTE_EYEDEPTH(o.fogParams.y);
#endif

#define GEN_FOG_FRAG(o) o.fogParams.x = mul(UNITY_MATRIX_MV, v.vertex).z; COMPUTE_EYEDEPTH(o.fogParams.y);
#define APPLY_FOG_FRAG(IN) IN.fogParams.x = saturate((FogStart + IN.fogParams.x) / (FogStart - FogEnd));

#define GEN_PROJ_COORD(o) o.texProjCoord = mul(_Object2World, v.vertex); o.texProjCoord = mul(_ProjMatrix, o.texProjCoord);

#define APPLY_VOL_FOG(c) IN.texProjCoord.x = IN.texProjCoord.x / IN.texProjCoord.w / 2.0f + 0.5f; IN.texProjCoord.y = IN.texProjCoord.y / IN.texProjCoord.w / 2.0f + 0.5f; IN.texProjCoord.xy = IN.texProjCoord.xy * 4  + frac(half2(_Time.x, 0) * _WindSpeed); c = saturate(tex2D(_FogNoise, IN.texProjCoord.xy).r);;//	c *= saturate(tex2D(_FogNoise, IN.texProjCoord.xy + frac(half2(0.5,_Time.x) * _WindSpeed * 1.5)).r);
	
#define APPLY_FOG_COLOR(c, IN) c.rgb = lerp(c.rgb, FogColor, IN.fogParams.x);
#define FOG_FACTOR IN.fogParams.x
#define FOG_COLOR FogColor
#define OUTPUT_DEPTH(c, IN) c.a = 1 - saturate(IN.fogParams.y / 300);
