using UnityEngine;
using System.Collections.Generic;
using UnityEngine.EventSystems;

public class MonoBase : MonoBehaviour 
{
    public static System.Action<Touch[]> _OnTouchesDetected;
    public static System.Action<Swipe> _OnSwiped;

    public static System.Action<Object> _OnObjectHeld;
    public static System.Action<Object> _OnObjectReleased;
    public static System.Action<Object> _OnObjectDown;

    private const float m_SwipeDetectDiff = 20.0f;

#if (UNITY_ANDROID || UNITY_IOS) && !UNITY_EDITOR
    private Vector3[] m_StartPositions = new Vector3[10];
    private Vector3[] m_EndPositions = new Vector3[10];
#endif

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
#if UNITY_EDITOR
        if (Input.GetMouseButton(0))
        {
            Object ob = GetCanvasObjectAt(Input.mousePosition);
            if (ob != null && _OnObjectHeld != null)
                _OnObjectHeld(ob);
        }

        if (Input.GetMouseButtonDown(0))
        {
            Object ob = GetCanvasObjectAt(Input.mousePosition);
            if (ob != null && _OnObjectDown != null)
                _OnObjectDown(ob);
        }

        if (Input.GetMouseButtonUp(0))
        {
            Object ob = GetCanvasObjectAt(Input.mousePosition);
            if (ob != null && _OnObjectReleased != null)
                _OnObjectReleased(ob);
        }
#elif UNITY_ANDROID || UNITY_IOS
        if (Input.touchCount > 0)
        {
            if (_OnTouchesDetected != null)
                _OnTouchesDetected(Input.touches);

            //Check Swipes
            Touch[] touches = Input.touches;

            for (int i = 0; i < ((touches.Length > 10) ? 10 : touches.Length); i++)
            {
                Object ob = GetCanvasObjectAt(touches[i].position);
                if (ob != null && _OnObjectHeld != null)
                    _OnObjectHeld(ob);

                if (touches[i].phase == TouchPhase.Began)
                {
                    m_StartPositions[i] = touches[i].position;
                    m_EndPositions[i] = Vector3.zero;
                    //Object ob = GetCanvasObjectAt(touches[i].position);
                    if (ob != null && _OnObjectReleased != null)
                        _OnObjectDown(ob);
                }

                if (touches[i].phase == TouchPhase.Ended)
                {
                    m_EndPositions[i] = touches[i].position;
                    //Object ob = GetCanvasObjectAt(touches[i].position);
                    if (ob != null && _OnObjectReleased != null)
                        _OnObjectReleased(ob);
                }

                if (m_StartPositions[i] != Vector3.zero && m_EndPositions[i] != Vector3.zero && Vector3.Distance(m_StartPositions[i], m_EndPositions[i]) > m_SwipeDetectDiff)
                {
                    Swipe swipe = new Swipe(m_StartPositions[i], m_EndPositions[i]);
                    if (_OnSwiped != null)
                        _OnSwiped(swipe);
                    m_StartPositions[i] = Vector3.zero;
                    m_EndPositions[i] = Vector3.zero;
                }
            }
        }
#endif
    }

    private Object GetCanvasObjectAt(Vector3 a_Position)
    {
        if (EventSystem.current == null)
            return null;

        PointerEventData ped = new PointerEventData(EventSystem.current);
        ped.position = a_Position;

        if (ped == null)
            return null;

        List<RaycastResult> rayRes = new List<RaycastResult>();
        EventSystem.current.RaycastAll(ped, rayRes);

        if (rayRes.Count > 0)
        {
            for (int i = 0; i < rayRes.Count; i++)
            {
                if (rayRes[i].gameObject != null)
                {
                    Object ob = (Object)rayRes[i].gameObject;
                    return ob;
                }
            }
        }

        return null;
    }
}
