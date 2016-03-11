using UnityEngine;
using System.Collections;

public class MonoBase : MonoBehaviour 
{
    public static System.Action<Touch[]> _OnTouchesDetected;
    public static System.Action<Swipe> _OnSwiped;

    private const float m_SwipeDetectDiff = 20.0f;

    private Vector3[] m_StartPositions = new Vector3[10];
    private Vector3[] m_EndPositions = new Vector3[10];

    private Transform m_Transform;
    public new Transform transform 
    { 
        get 
        {
            if (m_Transform == null)
                m_Transform = gameObject.transform;

            return m_Transform; 
        } 
    }

    private Renderer m_Renderer;
    public new Renderer renderer
    {
        get 
        {
            if (m_Renderer == null)
                m_Renderer = gameObject.GetComponent<Renderer>();

            return m_Renderer;
        }
    }

    private Collider m_Collider;
    public new Collider collider
    {
        get
        {
            if (m_Collider == null)
                m_Collider = gameObject.GetComponent<Collider>();

            return m_Collider;
        }
    }

    protected virtual void Update()
    {
//#if UNITY_EDITOR
//        //Do nothing
//#else
        if (Input.touchCount > 0)
        {
            if (_OnTouchesDetected != null)
                _OnTouchesDetected(Input.touches);

            //Check Swipes
            Touch[] touches = Input.touches;

            for (int i = 0; i < ((touches.Length > 10) ? 10 : touches.Length); i++)
            {
                if (touches[i].phase == TouchPhase.Began)
                {
                    m_StartPositions[i] = touches[i].position;
                    m_EndPositions[i] = Vector3.zero;
                    //Debug.Log("Begun: " + i);
                }

                if (touches[i].phase == TouchPhase.Ended)
                {
                    m_EndPositions[i] = touches[i].position;
                    //Debug.Log("Ended: " + i);
                }

                if (m_StartPositions[i] != Vector3.zero && m_EndPositions[i] != Vector3.zero && Vector3.Distance(m_StartPositions[i], m_EndPositions[i]) > m_SwipeDetectDiff)
                {
                    //Debug.Log("Swiped::" + i + "::" + m_StartPositions[i] + "::" + m_EndPositions[i]);
                    Swipe swipe = new Swipe(m_StartPositions[i], m_EndPositions[i]);
                    if (_OnSwiped != null)
                        _OnSwiped(swipe);
                    m_StartPositions[i] = Vector3.zero;
                    m_EndPositions[i] = Vector3.zero;
                }
            }
        }
//#endif
    }
}
