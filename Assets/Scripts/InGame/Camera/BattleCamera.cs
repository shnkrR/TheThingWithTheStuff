using UnityEngine;
using System.Collections;

public class BattleCamera : MonoBase 
{
    public Vector3 _LocalOffset;
    public Vector3 _MaxDistance;

    private Transform m_PlayerTransform;
    private Transform m_AITransform;


    private void Start()
    {
        Init();
    }

    private void Init()
    {
        m_AITransform = GameObject.Find("AI").transform;
        m_PlayerTransform = GameObject.Find("Player").transform;
    }

    private void Update()
    {
        float distance = Vector3.Distance(m_AITransform.position, m_PlayerTransform.position);
        Vector3 dest = new Vector3(distance / 5.0f, _LocalOffset.y, _LocalOffset.z);

        transform.position = Vector3.Lerp(transform.position, dest, Time.deltaTime * 15.0f);
        transform.LookAt((m_AITransform.position + m_PlayerTransform.position) / 2.0f);
    }
}
