using UnityEngine;
using System.Collections;

public class UIBlur : MonoBehaviour 
{

    const int m_iPass_Composite = 0;
    const int m_iPass_Downsample = 1;
    const int m_iPass_Blur = 2;

    public Shader blurShader = null;
    public float m_fBlurSize = 4.0f;
    public float m_fDownscaleFactor = 5.0f;
    public int m_iBloomIterations = 2;

    Material m_PPMat = null;
    bool m_bMatCreated = false;
    public bool m_iBlur = false;
    public Color m_cBgColor = Color.blue;

	// Use this for initialization
	void Start () 
    {          
	}

    void CheckShaderAndCreateMaterial(ref Shader a_iPPShader)
    {
        if (a_iPPShader != null)
        {
            if (m_PPMat == null || m_PPMat.shader != a_iPPShader)
            {
                m_PPMat = new Material(a_iPPShader);
                if (m_PPMat != null)
                {
                    m_PPMat.hideFlags = HideFlags.DontSave;
                    m_bMatCreated = true;                    
                }
            }
        }
    }

    bool CheckResources()
    {
        if (!m_bMatCreated && blurShader != null)
        {
            CheckShaderAndCreateMaterial(ref blurShader);
        }

        return m_bMatCreated;
    }

    void OnRenderImage(RenderTexture a_Src, RenderTexture a_Dest)
    {
        if (!CheckResources())
        {
            Graphics.Blit(a_Src, a_Dest);
            enabled = false;
            return;
        }


        FilterMode RTFilterMode = FilterMode.Bilinear;

        float refHeight = 512;
        float refWidth = (float)Screen.width / (float)Screen.height * refHeight;

        RenderTextureFormat rtFormat = RenderTextureFormat.Default;

        int ScreenHeight2 = Screen.height / 2;
        int ScreenWidth2 = Screen.width / 2;

        int ScreenHeight4 = (int)(Screen.height / m_fDownscaleFactor);
        int ScreenWidth4 = (int)(Screen.width / m_fDownscaleFactor);

        //Downscale
        RenderTexture rtDown2 = RenderTexture.GetTemporary(ScreenWidth2, ScreenHeight2, 0, rtFormat);
        rtDown2.filterMode = RTFilterMode;
        RenderTexture rtDown4 = RenderTexture.GetTemporary(ScreenWidth4, ScreenHeight4, 0, rtFormat);
        rtDown4.filterMode = RTFilterMode;
        //RenderTexture rtDown8 = RenderTexture.GetTemporary(ScreenWidth8, ScreenHeight8, 0, rtFormat);
        //rtDown8.filterMode = RTFilterMode;

        //Downsample the render texture
        //1/2
        Graphics.Blit(a_Src, rtDown2, m_PPMat, m_iPass_Downsample);
        //1/5
        Graphics.Blit(rtDown2, rtDown4, m_PPMat, m_iPass_Downsample);

        //Bloom 
        RenderTexture rtBloom = null;

        int bloomRTWidth = ScreenWidth4;
        int bloomRTHeight = ScreenHeight4;

        RenderTexture tempBlurTexture = RenderTexture.GetTemporary(bloomRTWidth, bloomRTHeight, 0, rtFormat);
        tempBlurTexture.filterMode = RTFilterMode;

        if (m_iBloomIterations > 0)
        {
            m_PPMat.SetVector("_BloomParams", new Vector4(1.0f / refWidth, 1.0f / refHeight, 1, 0));
            rtBloom = RenderTexture.GetTemporary(bloomRTWidth, bloomRTHeight, 0, rtFormat);
            rtBloom.filterMode = RTFilterMode;

            for (int iCount = 0; iCount < m_iBloomIterations; iCount++)
            {
                float blurSize = m_fBlurSize;// *(1 + iCount * 0.5f);

                //Vertical Blur
                m_PPMat.SetVector("_Offsets", new Vector4(0, blurSize, 0, 0));
                if (iCount == 0)
                {
                    Graphics.Blit(rtDown4, tempBlurTexture, m_PPMat, m_iPass_Blur);
                }
                else
                {
                    tempBlurTexture.DiscardContents();
                    Graphics.Blit(rtBloom, tempBlurTexture, m_PPMat, m_iPass_Blur);
                    rtBloom.DiscardContents();
                }

                //Horizontal Blur
                m_PPMat.SetVector("_Offsets", new Vector4(blurSize, 0, 0, 0));
                Graphics.Blit(tempBlurTexture, rtBloom, m_PPMat, m_iPass_Blur);
            }

            RenderTexture.ReleaseTemporary(tempBlurTexture);

            if(m_iBlur)
                m_PPMat.SetTexture("_Bloom", rtBloom);
            else
                m_PPMat.SetTexture("_Bloom", a_Src);
        }

        m_PPMat.SetColor("_BgColor", m_cBgColor);

        Graphics.Blit(a_Src, a_Dest, m_PPMat, m_iPass_Composite);

        if (rtBloom != null)
        {
            RenderTexture.ReleaseTemporary(rtBloom);
        }

        if (rtDown4 != null)
        {
            RenderTexture.ReleaseTemporary(rtDown4);
        }

        if (rtDown2 != null)
        {
            RenderTexture.ReleaseTemporary(rtDown2);
        }
    }
       
}
