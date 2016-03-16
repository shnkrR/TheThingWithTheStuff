//using UnityEngine;
//using System.Collections;
//
//public class Player : MonoBehaviour 
//{
//    public float _ForwardMoveSpeed = 15.0f;
//    public float _SidewaysMoveSpeed = 15.0f;
//
//    public float _ApproachLimit = 5.0f;
//
//    [Range(0.1f, 1.0f)]
//    public float _SpeedDampener = 0.5f;
//
//    private Transform mTransform;
//    private Transform mTarget;
//
//    private Camera mPlayerCamera;
//
//    private Vector3 mMoveDirection;
//    private Vector3 mMoveSpeed;
//
//    private bool mSideways;
//
//    private float mDefaultForwardSpeed;
//
//
//	void Start () 
//	{
//        mTransform = transform;
//
//        mMoveDirection = Vector3.zero;
//        mMoveSpeed = Vector3.zero;
//
//        GameObject cam = mTransform.FindChild("Main Camera").gameObject;
//        if(cam != null)
//            mPlayerCamera = cam.GetComponent<Camera>();
//        if (mPlayerCamera == null)
//            mPlayerCamera = Camera.main;
//
//        mSideways = false;
//        mDefaultForwardSpeed = _ForwardMoveSpeed;
//    }
//	
//	void Update () 
//	{
//#if UNITY_EDITOR      
//        HandleEditorInputs();
//#elif UNITY_ANDROID || UNITY_IOS
//        HandleMobileInputs();
//#endif
//    }
//
//    void HandleEditorInputs()
//    {
//        bool noInput = true;
//        mSideways = false;
//
//        if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow))
//        {
//            noInput = false;
//            mMoveDirection = mTransform.forward;
//            mMoveSpeed = ((mMoveDirection * _ForwardMoveSpeed));
//
//            if (mTarget != null && Vector3.Distance(mTarget.position, mTransform.position) < _ApproachLimit)
//            {
//                noInput = true;
//                mMoveSpeed = Vector3.zero;
//                mMoveDirection = Vector3.zero;
//            }
//        }
//        else if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow))
//        {
//            noInput = false;
//            mMoveDirection = -mTransform.forward;
//            mMoveSpeed = ((mMoveDirection * _ForwardMoveSpeed));
//        }
//        else
//        if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
//        {
//            noInput = false;
//            mSideways = true;       
//            mMoveDirection = -mTransform.right;
//            mMoveSpeed = ((mMoveDirection * _SidewaysMoveSpeed));
//        }
//        else if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
//        {
//            noInput = false;
//            mSideways = true;
//            mMoveDirection = mTransform.right;
//            mMoveSpeed = ((mMoveDirection * _SidewaysMoveSpeed));
//        }
//
//        if (noInput)
//        {
//            mMoveSpeed = Vector3.Lerp(mMoveSpeed, Vector3.zero, Mathf.Clamp(_SpeedDampener, 0.1f, 1.0f));
//        }
//    }
//
//    void HandleMobileInputs()
//    {
//        bool noInput = false;
//        mSideways = false;
//
//        _ForwardMoveSpeed = mDefaultForwardSpeed;
//
//        if (Joystick.pJoystickDirection.y > 0.0f && mTarget != null && Vector3.Distance(mTarget.position, mTransform.position) < _ApproachLimit)
//        {
//            noInput = true;
//            _ForwardMoveSpeed = 0.0f;
//        }
//
//        if (Joystick.pJoystickDirection.x != 0.0f && (Joystick.pJoystickDirection.y < 0.2f && Joystick.pJoystickDirection.y > -0.2f))
//        {
//            mSideways = true;
//            _ForwardMoveSpeed /= 2.0f;
//        }
//
//        if (Joystick.pJoystickDirection == Vector3.zero)
//            noInput = true;
//        else
//        {
//            noInput = false;
//            mMoveDirection = (mTransform.forward * (Joystick.pJoystickDirection.y * _ForwardMoveSpeed)) + (mTransform.right * (Joystick.pJoystickDirection.x * _SidewaysMoveSpeed));
//            mMoveSpeed = mMoveDirection;
//        }            
//
//        if (noInput)
//        {
//            mMoveSpeed = Vector3.Lerp(mMoveSpeed, Vector3.zero, Mathf.Clamp(_SpeedDampener, 0.1f, 1.0f));
//        }
//    }
//
//    void LateUpdate()
//    {
//        float oldDist = Vector3.Distance(mTransform.position, mTarget.position);
//        mTransform.position += (mMoveSpeed * Time.deltaTime);
//
//        if (mTarget != null)
//            mTransform.LookAt(mTarget);
//        else
//            mTransform.LookAt(mTransform.forward + new Vector3(0.0f, 0.0f, 10.0f));
//
//        float newDist = Vector3.Distance(mTransform.position, mTarget.position);
//
//        if (mSideways && mTarget != null)
//        {            
//            float diffDist = newDist - oldDist;
//            mTransform.position += (mTransform.forward * diffDist);
//        }        
//    }
//
//    public void SetTarget(GameObject inTarget)
//    {
//        mTarget = inTarget.transform;
//    }
//}
