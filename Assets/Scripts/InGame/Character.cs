using UnityEngine;
using System.Collections;

public class Character : MonoBase 
{
    public Animator _Animator;

    public float _TravelDistance = 2.5f;
    public float _LerpDelta = 20.0f;

    private bool m_InputTaken = false;

    private Vector3 m_DestinationPosition;


    private void Start()
    {
        _OnSwiped += OnSwipe;

        m_InputTaken = false;

        _Animator.SetInteger("MoveStateIndex", 0);
        _Animator.SetBool("Move", false);
        _Animator.SetBool("Attack", false);

        m_DestinationPosition = transform.position;
    }

    private void OnDestroy()
    {
        _OnSwiped -= OnSwipe;
    }

    protected override void Update()
    {
        base.Update();

        //if (!GameManager.pInstance.IsMobile())
            HandleInputs();
        //else
        {
            if (m_InputTaken)
            {
                if (Vector3.Distance(transform.position, m_DestinationPosition) > 0.5f)
                    transform.position = Vector3.Lerp(transform.position, m_DestinationPosition, Time.deltaTime * _LerpDelta);
                else
                {
                    m_DestinationPosition = transform.position;
                    m_InputTaken = false;

                    _Animator.SetBool("Move", false);
                    _Animator.SetBool("Attack", false);
                    _Animator.SetInteger("MoveStateIndex", 0);
                }
            }
        }
    }
	
	void HandleInputs () 
	{
        //m_InputTaken = false;
        if (m_InputTaken)
            return;

        if (Input.GetKey(KeyCode.W))
        {
            _Animator.SetBool("Move", true);
            _Animator.SetBool("Attack", false);
            _Animator.SetInteger("MoveStateIndex", 1);
            m_DestinationPosition = transform.position + new Vector3(0.0f, 0.0f, _TravelDistance);
            m_InputTaken = true;
        }
        else if (Input.GetKey(KeyCode.S))
        {
            
            _Animator.SetBool("Move", true);
            _Animator.SetBool("Attack", false);
            _Animator.SetInteger("MoveStateIndex", 2);
            m_DestinationPosition = transform.position + new Vector3(0.0f, 0.0f, -_TravelDistance);
            m_InputTaken = true;
        }

        if (Input.GetKey(KeyCode.A))
        {
            
            _Animator.SetBool("Move", true);
            _Animator.SetBool("Attack", false);
            _Animator.SetInteger("MoveStateIndex", 3);
            m_DestinationPosition = transform.position + new Vector3(-_TravelDistance, 0.0f, 0.0f);
            m_InputTaken = true;
        }
        else if (Input.GetKey(KeyCode.D))
        {
            _Animator.SetBool("Move", true);
            _Animator.SetBool("Attack", false);
            _Animator.SetInteger("MoveStateIndex", 4);
            m_DestinationPosition = transform.position + new Vector3(_TravelDistance, 0.0f, 0.0f);
            m_InputTaken = true;
        }
	}

    void OnSwipe(Swipe a_Swipe)
    {
        m_InputTaken = true;
        Vector3 dest = transform.position;

        //Debug.Log("Swipe Direction: " + a_Swipe.p_SwipeDirection.ToString() + " Swipe Start: " + a_Swipe.p_StartPosition + " Swipe End: " + a_Swipe.p_EndPosition);
        switch (a_Swipe.p_SwipeDirection)
        {
            case Swipe.SwipeDirection.Up:
                _Animator.SetBool("Move", true);
                _Animator.SetBool("Attack", false);
                _Animator.SetInteger("MoveStateIndex", 1);
                dest += new Vector3(0.0f, 0.0f, _TravelDistance);
                break;

            case Swipe.SwipeDirection.Down:
                _Animator.SetBool("Move", true);
                _Animator.SetBool("Attack", false);
                _Animator.SetInteger("MoveStateIndex", 2);
                dest += new Vector3(0.0f, 0.0f, -_TravelDistance);
                break;

            case Swipe.SwipeDirection.Left:
                _Animator.SetBool("Move", true);
                _Animator.SetBool("Attack", false);
                _Animator.SetInteger("MoveStateIndex", 3);
                dest += new Vector3(-_TravelDistance, 0.0f, 0.0f);
                break;

            case Swipe.SwipeDirection.Right:
                _Animator.SetBool("Move", true);
                _Animator.SetBool("Attack", false);
                _Animator.SetInteger("MoveStateIndex", 4);
                dest += new Vector3(_TravelDistance, 0.0f, 0.0f);
                break;
        }

        m_DestinationPosition = dest;
    }
}
