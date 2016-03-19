using UnityEngine;
using System.Collections;

public class BattleCamera : MonoBase 
{
    public Vector3 _LocalOffset;
    public Vector3 _LookAtOffset;

    private Transform m_PlayerTransform;
    private Transform m_AITransform;


    private void Init()
    {
        m_AITransform = GameObject.Find("AI").transform;
        m_PlayerTransform = GameObject.Find("Player").transform;

        transform.position = m_PlayerTransform.position + _LocalOffset;
        transform.LookAt(m_AITransform.position);
    }

    void Start()
    {
        Init();
    }

    void LateUpdate()
    {
        //float straightLineFromCam = m_playerCamera.transform.position - (m_playerCamera.transform.position);
        float deltaZ = m_AITransform.position.z - m_PlayerTransform.position.z;
        float deltaX = m_AITransform.position.x - m_PlayerTransform.position.x;
        
        float angle = Mathf.Atan2(deltaX, deltaZ) * (180 / Mathf.PI);
        //angle -= 180.0f;
        //Debug.Log("angle|" + angle);

        Vector3 rot = transform.localEulerAngles;
        rot.y = Mathf.LerpAngle(rot.y, angle, Time.deltaTime * 10.0f);

        transform.localEulerAngles = rot;
        transform.position = m_PlayerTransform.position;
        transform.position += (transform.forward * _LocalOffset.z);
        transform.position += new Vector3(_LocalOffset.x, _LocalOffset.y, 0.0f);

        float dist = Vector3.Distance(transform.position, m_PlayerTransform.position);
        if (dist < Mathf.Abs(_LocalOffset.z))
        {
            float ideal = Mathf.Abs(_LocalOffset.z);
            float diff = ideal - dist;

            transform.position -= (transform.forward * diff);
        }
    }
}
