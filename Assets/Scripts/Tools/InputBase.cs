using UnityEngine;
using System.Collections;

public struct Swipe
{
    public enum SwipeDirection
    {
        Left,
        Right,
        Up,
        Down,
    }

    public Swipe(Vector2 a_StartPosition, Vector2 a_EndPosition)
    {
        m_StartPosition = a_StartPosition;
        m_EndPosition = a_EndPosition;
    }

    private Vector2 m_StartPosition;
    public Vector2 p_StartPosition { get { return m_StartPosition; } }

    private Vector2 m_EndPosition;
    public Vector2 p_EndPosition { get { return m_EndPosition; } }

    public float p_XDiff { get { return m_EndPosition.x - m_StartPosition.x; } }
    public float p_YDiff { get { return m_EndPosition.y - m_StartPosition.y; } }

    public SwipeDirection p_SwipeDirection 
    { 
        get 
        { 
            return (Mathf.Abs(p_XDiff) > Mathf.Abs(p_YDiff)) ? ((p_XDiff < 0) ? SwipeDirection.Left : SwipeDirection.Right) : ((p_YDiff < 0) ? SwipeDirection.Down : SwipeDirection.Up); 
        } 
    }
}
