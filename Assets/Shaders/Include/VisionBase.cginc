sampler2D _HeatLookup;

inline half4 GetHeatVisionOp(half4 c)
{
	c.rgb *= (c.a * 3 + 0.6);	
	c.rgb = lerp(half3(0.1, 0.1, 0.1), c.rgb, 0.3);	
	c = tex2D(_HeatLookup, half2(Luminance(c.rgb), 0.5));
	return c;	
}

inline half4 GetFlirVisionOp(half4 c)
{
	c.rgb *= (c.a * 3 + 0.6);	
	c.rgb = lerp(half3(0.1, 0.1, 0.1), c.rgb, 0.4);	
	half lum = Luminance(c.rgb);
	c.rgb = half3(lum, lum, lum);

	return c;
}

inline half4 GetFlirBlackVisionOp(half4 c)
{
	c.rgb *= (c.a * 3 + 0.6);	
	c.rgb = lerp(half3(0.1, 0.1, 0.1), c.rgb, 0.4);	
	half lum = saturate(0.4 - Luminance(c.rgb));
	c.rgb = half3(lum, lum, lum);

	return c;
}

inline half4 GetNightVisionOp(half4 c)
{
	c.rgb *= (c.a * 3 + 0.6);	
	c.rgb *= half3(0.1, 0.95, 0.2);
	return c;
}

inline half4 GetENV(half4 c)
{
	c.rgb *= (c.a * 3 + 0.6);	
	c.rgb = lerp(c.rgb * half3(0.1, 0.95, 0.2), tex2D(_HeatLookup, half2(0.75, 0.5)), c.a * 1.3);
	return c;
}

inline half4 GetCurrectOp(half4 c)
{
	#if NIGHTVISION
		return GetNightVisionOp(c);
	#endif

	#if HEATVISION
		return GetHeatVisionOp(c);
	#endif

	#if FLIR
		return GetFlirVisionOp(c);
	#endif

	#if FLIR_BLACK
		return GetFlirBlackVisionOp(c);
	#endif

	#if ENV
		return GetENV(c);
	#endif

	return c;
}