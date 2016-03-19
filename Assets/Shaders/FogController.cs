using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class FogController : MonoBehaviour 
{
	[System.Serializable]
	public struct FogVaues
	{
		public float fStartTime;
		public float fEndTime;
		public float fFogStartValue;
		public float fFogEndValue;
	};

    [Tooltip("Fog start distance.")]
    public float FogStart = 1000.0f;

    [Tooltip("Fog end distance. At this point and further the fog intensity is the highest.")]
    public float FogEnd = 1001.0f;

	[Tooltip("Set it true if you want the fog to applied in world space rather than in traditional view space. Enable it for FOG OF WAR kind of effect.")]
	public bool InWorldSpace = false;

    [Tooltip("Height at which the fog starts.")]
    public float FogHeightStart = -100.0f;

    [Tooltip("Height at which the fog ends.")]
    public float FogHeightEnd = 500.0f;

    [Tooltip("Color of the fog.")]
    public Color FogColor = Color.white;

    [Tooltip("Volumetric fog texture.")]
    public Texture2D VolFogTexture = null;
    public float WindSpeed = 1.0f;

    private Matrix4x4 m_matView = Matrix4x4.identity;
    private Matrix4x4 m_matProj = Matrix4x4.identity;

    [Tooltip("Materials which has glow property will be effected.")]
	public float m_fGlowMult = 0.0f;

    [Tooltip("Shadow plane height for dynamic planar shadows.")]
    public float m_fShadowPlaneHeight = 0.0f;

    [Tooltip("Enable this for fog fade in and out.")]
    public bool FogDelay = false;   

    float m_fCurrTime = 0.0f;

    [Tooltip("The rate at which fog fades in.")]
    public float FogFadeInSpeed = 0.5f;

	[Tooltip("The rate at which fog fades out.")]
	public float FogFadeOutSpeed = 0.5f;
    
    private float m_fFogEndCurrValue = 0;
	private float m_fFogStartCurrValue = 1;

	public Transform m_DroneAnchor = null;

	public FogVaues[] fogValues;
	
	//FOR PLAYER VEHCILES
	public Color32 m_fVehicleColor = Color.white;
	public Color32 m_fPlayerVehicleColor = Color.white;

    //public bool SecondFogLayer = false;
   // public float SecondFogStart = 1000;
    //public float SecondFogEnd = 1001;

    //[Tooltip("Fog intenity animation curve.")]
	//private AnimationCurve FogIntensity = AnimationCurve.Linear(0, 1, 0, 1);

	// Use this for initialization
	void Start () 
    {
		if(InWorldSpace)
		{
			Shader.DisableKeyword("VIEW_SPACE");
			Shader.EnableKeyword("WORLD_SPACE");
		}
		else
		{
			Shader.DisableKeyword("WORLD_SPACE");
			Shader.EnableKeyword("VIEW_SPACE");
		}

		if(m_DroneAnchor != null)
		{
			Shader.SetGlobalVector("_DroneAnchor", m_DroneAnchor.position);
		}
		else
		{
			Shader.SetGlobalVector("_DroneAnchor", Vector3.zero);
		}

		m_matView = transform.worldToLocalMatrix;
		m_matProj = Matrix4x4.Perspective(60.0f, 1, 1, 1000).transpose;
		Shader.SetGlobalMatrix("_ProjMatrix", m_matProj * m_matView);
		Shader.SetGlobalTexture("_FogNoise", VolFogTexture);
		Shader.SetGlobalFloat("_WindSpeed", WindSpeed);

        m_fFogEndCurrValue = FogEnd;
		m_fFogStartCurrValue = FogStart;

        Shader.SetGlobalFloat("FogStart", FogStart);
        Shader.SetGlobalFloat("FogEnd", FogEnd);
        Shader.SetGlobalColor("FogColor", FogColor);
		Shader.SetGlobalFloat ("_GlowMult", m_fGlowMult);
        Shader.SetGlobalFloat("fPlaneLocY", m_fShadowPlaneHeight);
        Shader.SetGlobalFloat("FogHeightStart", FogHeightStart);
        Shader.SetGlobalFloat("FogHeightEnd", FogHeightEnd);
		Shader.SetGlobalFloat("_FogMult", 1.0f);
		Shader.SetGlobalColor("_VehicleColor1", m_fPlayerVehicleColor);

	}

	

	// Update is called once per frame
	void Update ()
    {
#if UNITY_EDITOR

        m_matView = transform.worldToLocalMatrix;
        m_matProj = Matrix4x4.Perspective(60.0f, 1, 1, 1000).transpose;

        Shader.SetGlobalMatrix("_ProjMatrix", m_matProj * m_matView);
        Shader.SetGlobalTexture("_FogNoise", VolFogTexture);
        Shader.SetGlobalFloat("_WindSpeed", WindSpeed);

        Shader.SetGlobalFloat("FogStart", FogStart);

        Shader.SetGlobalColor("FogColor", FogColor);
        Shader.SetGlobalFloat("_GlowMult", m_fGlowMult);
        Shader.SetGlobalFloat("fPlaneLocY", m_fShadowPlaneHeight);
        Shader.SetGlobalFloat("FogHeightStart", FogHeightStart);
        Shader.SetGlobalFloat("FogHeightEnd", FogHeightEnd);

		if(m_DroneAnchor != null)
		{
			Shader.SetGlobalVector("_DroneAnchor", m_DroneAnchor.position);
		}
		else
		{
			Shader.SetGlobalVector("_DroneAnchor", Vector3.zero);
		}

		if(InWorldSpace)
		{
			Shader.DisableKeyword("VIEW_SPACE");
			Shader.EnableKeyword("WORLD_SPACE");
		}
		else
		{
			Shader.DisableKeyword("WORLD_SPACE");
			Shader.EnableKeyword("VIEW_SPACE");
		}

		Shader.SetGlobalColor("_VehicleColor1", m_fPlayerVehicleColor);


#endif

		Shader.SetGlobalColor("_VehicleColor", m_fVehicleColor);
        if (FogDelay)
        {
            m_fCurrTime += Time.deltaTime;

            //If FogEndTime < 0 then the fog doesn't fade out
            //if (FogEndTime > 0)
            {
				int currIdx = -1;
				for(int x=0 ; x < fogValues.Length ; x++)
				{
					if(m_fCurrTime > fogValues[x].fStartTime && m_fCurrTime < fogValues[x].fEndTime)
					{
						currIdx = x;
						break;
					}
				}

				if(currIdx > -1 && currIdx < fogValues.Length)
				{
					if (m_fCurrTime > fogValues[currIdx].fStartTime && m_fCurrTime < fogValues[currIdx].fEndTime)
					{
						m_fFogEndCurrValue = Mathf.Lerp(m_fFogEndCurrValue, fogValues[currIdx].fFogEndValue, Time.deltaTime * FogFadeInSpeed);
						m_fFogStartCurrValue = Mathf.Lerp(m_fFogStartCurrValue, fogValues[currIdx].fFogStartValue, Time.deltaTime * FogFadeInSpeed);
					}				

				}
				else
				{
					m_fFogEndCurrValue = Mathf.Lerp(m_fFogEndCurrValue, FogEnd, Time.deltaTime * FogFadeOutSpeed);
					m_fFogStartCurrValue = Mathf.Lerp(m_fFogStartCurrValue, FogStart, Time.deltaTime * FogFadeInSpeed);
				}
               
            }
           /* else
            {
                if (m_fCurrTime > FogStartTime)
                {
                    m_fFogEndCurrValue = Mathf.Lerp(m_fFogEndCurrValue, FogEndFinalValue, Time.deltaTime * FogFadeSpeed);
                }
            }*/
        }
        else
        {           
			m_fFogEndCurrValue = FogEnd;
			m_fFogStartCurrValue = FogStart;
        }

        Shader.SetGlobalFloat("FogEnd", m_fFogEndCurrValue);
		Shader.SetGlobalFloat("FogStart", m_fFogStartCurrValue);


        /*if (FogIntensity != null)
        {
			Debug.Log("Evaluating");
            Shader.SetGlobalFloat("_FogMult", FogIntensity.Evaluate(Time.time));
        }
        else
        {
			Debug.Log("Setting 1");
            Shader.SetGlobalFloat("_FogMult", 1);
        }*/
	}
}
