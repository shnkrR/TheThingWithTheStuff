using UnityEngine;
using System.Collections;

public class Character : MonoBase 
{
    public Animator _Animator;

    void Update()
    {
        HandleInputs();
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
}
