using UnityEngine;
using System.Collections;

public class Character : MonoBase 
{
    public Animator _Animator;


    private void Start()
    {
        _OnSwiped += OnSwipe;
        _OnTouchesDetected += OnTouch;
    }

    private void OnDestroy()
    {
        _OnSwiped -= OnSwipe;
        _OnTouchesDetected -= OnTouch;
    }

    protected override void Update()
    {
        base.Update();

        //if (!GameManager.pInstance.IsMobile())
            HandleInputs();
        //else
        {

        }
    }
	
	void HandleInputs () 
	{
        bool inputTaken = false;

        if (Input.GetKey(KeyCode.W))
        {
            _Animator.SetFloat("Forward", 1.0f);
            inputTaken = true;
        }
        else if (Input.GetKey(KeyCode.S))
        {
            _Animator.SetFloat("Forward", 2.0f);
            inputTaken = true;
        }

        if (Input.GetKey(KeyCode.A))
        {
            _Animator.SetFloat("Strafe", 1.0f);
            inputTaken = true;
        }
        else if (Input.GetKey(KeyCode.D))
        {
            _Animator.SetFloat("Strafe", 2.0f);
            inputTaken = true;
        }

        if (!inputTaken)
        {
            _Animator.SetFloat("Strafe", 0.0f);
            _Animator.SetFloat("Forward", 0.0f);
        }
	}

    void OnTouch(Touch[] a_Touches)
    {
    }

    void OnSwipe(Swipe a_Swipe)
    {
        Debug.Log("Swipe Direction: " + a_Swipe.p_SwipeDirection.ToString() + " Swipe Start: " + a_Swipe.p_StartPosition + " Swipe End: " + a_Swipe.p_EndPosition);
    }
}
