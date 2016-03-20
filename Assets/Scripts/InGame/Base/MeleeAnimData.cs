using UnityEngine;
using System.Collections;

public class MeleeAnimData 
{
    public float m_InputStartTime;
    public float m_InputExpireTime;
    public float m_HitTime;

    public float m_AnimLength;
    public int m_HitAtPercent;
    public int m_InputAtPercent;

    public MeleeAnimData(float a_InputStartTime, float a_InputExpireTime, float a_HitTime)
    {
        m_InputStartTime = a_InputStartTime;
        m_InputExpireTime = a_InputExpireTime;
        m_HitTime = a_HitTime;
    }

    public MeleeAnimData(float a_AnimLength, int a_HitAtPercent, int a_InputAtPercent, float a_Speed)
    {
        m_AnimLength = (a_AnimLength);
        m_HitAtPercent = a_HitAtPercent;
        m_InputAtPercent = a_InputAtPercent;

        m_InputExpireTime = m_AnimLength;
        m_InputStartTime = (m_InputExpireTime * (a_InputAtPercent / 100.0f));
        m_HitTime = (m_InputExpireTime * (m_HitAtPercent / 100.0f));
    }
}
