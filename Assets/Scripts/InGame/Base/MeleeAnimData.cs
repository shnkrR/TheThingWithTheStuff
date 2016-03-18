using UnityEngine;
using System.Collections;

public class MeleeAnimData 
{
    public float m_InputStartTime;
    public float m_InputExpireTime;
    public float m_HitTime;

    public MeleeAnimData(float a_InputStartTime, float a_InputExpireTime, float a_HitTime)
    {
        m_InputStartTime = a_InputStartTime;
        m_InputExpireTime = a_InputExpireTime;
        m_HitTime = a_HitTime;
    }
}
