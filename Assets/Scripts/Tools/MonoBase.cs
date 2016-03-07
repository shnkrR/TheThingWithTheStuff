using UnityEngine;
using System.Collections;

public class MonoBase : MonoBehaviour 
{
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
}
