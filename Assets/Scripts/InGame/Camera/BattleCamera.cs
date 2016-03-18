using UnityEngine;
using System.Collections;

public class BattleCamera : MonoBase 
{
    public Vector3 _LocalOffset;
    public Vector3 _MaxDistance;

    private Transform m_PlayerTransform;
    private Transform m_AITransform;

    private Vector3 m_LastAIPosition;

    private float m_CurrentX;


    private void Start()
    {
        m_AITransform = GameObject.Find("AI").transform;
        m_PlayerTransform = GameObject.Find("Player").transform;

        Init();
    }

    private void Init()
    {
        transform.position = m_PlayerTransform.position;
        transform.LookAt(m_AITransform.position);

        Vector3 dest = m_PlayerTransform.position + (transform.forward * _LocalOffset.z);
        dest += new Vector3(0.0f, _LocalOffset.y, 0.0f);

        transform.position = /*Vector3.Lerp(transform.position, */dest/*, Time.deltaTime * 20.0f)*/;

        m_CurrentX = transform.position.x;
    }

    private void Update()
    {
        float xDelta = m_PlayerTransform.position.x - transform.position.x;
        float yDelta = m_PlayerTransform.position.y - transform.position.y;
        float zDelta = m_PlayerTransform.position.z - transform.position.z;

        Vector3 dest = Vector3.zero;
        Vector3 playerpos = m_PlayerTransform.position;

        dest = new Vector3(transform.position.x, playerpos.y, playerpos.z);
        transform.position = dest;
        transform.LookAt(m_AITransform.position);
        transform.position += (transform.forward * (_LocalOffset.z));

        dest = new Vector3(dest.x, transform.position.y + _LocalOffset.y, transform.position.z);

        if (xDelta > 0)
        {
            if (xDelta > _MaxDistance.x)
            {
                m_CurrentX = Mathf.Lerp(transform.position.x, playerpos.x - _MaxDistance.x, Time.deltaTime * 5.0f);
                //dest = new Vector3(playerpos.x - _MaxDistance.x, playerpos.y + _LocalOffset.y, playerpos.z + _LocalOffset.z);
            }
        }
        else
        {
            if (xDelta < _MaxDistance.x)
            {
                m_CurrentX = Mathf.Lerp(transform.position.x, playerpos.x + _MaxDistance.x, Time.deltaTime * 5.0f);
                //dest = new Vector3(playerpos.x + _MaxDistance.x, playerpos.y + _LocalOffset.y, playerpos.z + _LocalOffset.z);
            }
        }

        dest.x = m_CurrentX;
        transform.position = dest;//Vector3.Lerp(transform.position, dest, Time.deltaTime * 10.0f);
        
        //if (zDelta > 0)
        //{
        //    if (zDelta > _MaxDistance.z)
        //    {
        //        Vector3 dest = new Vector3(playerpos.x, playerpos.y + _LocalOffset.y, playerpos.z - _MaxDistance.z);
        //        transform.position = Vector3.Lerp(transform.position, dest, Time.deltaTime * 50.0f);
        //    }
        //}
        //else
        //{
        //    if (zDelta < _MaxDistance.z)
        //    {
        //        Vector3 dest = new Vector3(playerpos.x, playerpos.y + _LocalOffset.y, playerpos.z + _MaxDistance.z);
        //        transform.position = Vector3.Lerp(transform.position, dest, Time.deltaTime * 50.0f);
        //    }
        //}
    }
}
