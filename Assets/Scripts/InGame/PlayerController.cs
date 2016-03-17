using UnityEngine;
using System.Collections;

public class PlayerController : MonoBase
{
    //BASE MOVEMENT VARIABLES
    private float m_fMovementSpeed;
    private float m_sMovementSpeed;
    private float m_inertia;
    private float m_TurnSpeed = 5.0f;
        
    //BASE COMBAT VARIABLES
    private float m_meleeDistance;
    private float m_meleeAttackRate;
    private float m_meleeDamage;
    private float m_clipCapacity;
    private float m_refireRate;
    private float m_rangedDamage;

    private Transform m_playerTransform;    
    private Transform m_enemyTransform;
    public Transform _AI { get { return m_enemyTransform; } }

    private Camera m_playerCamera;

    private Vector3 m_PrevMoveDirection;
    private Vector3 m_moveDirection;
    private Vector3 m_moveSpeed;

    private RobotBase m_robotBase;

    private WeaponBase m_weaponBase;

    private Animator m_animatorController;

    private bool noInput = true;

    private int m_dpadInput;
    

    public enum DpadDirections
    {
        NONE=0,
        FORWARD,
        BACK,
        LEFT,
        RIGHT
    }
        
    void Start()
    {            
        Initialise();            
    }

    void Initialise()
    {
        m_playerTransform = transform;

        m_robotBase = transform.GetComponent<RobotBase>(); 
        m_weaponBase = transform.GetComponent<WeaponBase>();

        SetPlayerStats();
        SetEnemy();

        m_moveDirection = Vector3.zero;
        m_moveSpeed = Vector3.zero;

        m_animatorController = transform.GetComponentInChildren<Animator>();
        m_animatorController.SetInteger("dir", 0);

        m_playerCamera = transform.GetComponentInChildren<Camera>(); 

        _OnObjectHeld += OnObjectHeld;
     }

    void SetPlayerStats()
    {
        m_fMovementSpeed = m_robotBase.m_fMovementSpeed;
        m_sMovementSpeed = m_robotBase.m_sMovementSpeed;
        m_inertia = m_robotBase.m_inertia;
        m_meleeDistance = m_robotBase.m_meleeDistance;
        m_clipCapacity = m_weaponBase.m_clipCapacity;
        m_meleeAttackRate = m_weaponBase.m_meleeAttackRate;
        m_meleeDamage = m_weaponBase.m_meleeDamage;
        m_refireRate = m_weaponBase.m_refireRate;
        m_rangedDamage = m_weaponBase.m_rangedDamage;
    }

    void SetEnemy()
    {
        m_enemyTransform = GameObject.Find("AI").transform;
    }

    #region Unity Functions
    void Update()
    {
        HandleMovementInputs();
        HandleCombatInputs();
    }

    void FixedUpdate()
    {
        m_dpadInput = 0;
    }

    void OnDestroy()
    {
        _OnObjectHeld -= OnObjectHeld;
    }

    void LateUpdate()
    {
        float oldDist = Vector3.Distance(m_playerTransform.position, m_enemyTransform.position);
        m_playerTransform.position += (m_moveSpeed * Time.deltaTime);

        m_playerTransform.LookAt(m_playerTransform.position + (m_moveSpeed));

        m_playerCamera.transform.localPosition = Vector3.zero;
        m_playerCamera.transform.LookAt(m_enemyTransform.position);
        m_playerCamera.transform.position += (m_playerCamera.transform.forward * -1.5f);
        m_playerCamera.transform.localPosition += new Vector3(0.0f, 0.75f, 0.0f);
    }
    #endregion

    #region System Events
    void OnObjectHeld(Object a_Object)
    {
        GameObject go = (GameObject)a_Object;

        if (go != null)
        {
            if (go.name == "DPad_Up")
                m_dpadInput = 1;
            else if (go.name == "DPad_Down")
                m_dpadInput = -1;
            else if (go.name == "DPad_Left")
                m_dpadInput = 2;
            else if (go.name == "DPad_Right")
                m_dpadInput = 3;
        }
    }
    #endregion
        
    void HandleMovementInputs()
    {
        noInput = true;
        DpadDirections moveDir = DpadDirections.NONE;


        if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow) || m_dpadInput == 1)
        {
            moveDir = DpadDirections.FORWARD;
            Move(moveDir);
        }
        else
        if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow) || m_dpadInput == -1)
        {
            moveDir = DpadDirections.BACK;
            Move(moveDir);
        }
        if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow) || m_dpadInput == 2)
        {
            moveDir = DpadDirections.LEFT;
            Move(moveDir);
        }
        else
        if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow) || m_dpadInput == 3)
        {
            moveDir = DpadDirections.RIGHT;
            Move(moveDir);
        }

        Move(moveDir);
    }
    
    void Move(DpadDirections a_Direction)
    {
        switch (a_Direction)
        {
            case DpadDirections.FORWARD:
                noInput = false;
                m_animatorController.SetInteger("dir", 1);
                m_moveDirection = Vector3.Lerp(m_moveDirection, m_playerCamera.transform.forward, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * m_fMovementSpeed));
                
                if (m_enemyTransform != null && Vector3.Distance(m_enemyTransform.position, m_playerTransform.position) < (m_meleeDistance * 2.0f))
                {
                    noInput = true;
                    m_moveSpeed = Vector3.zero;
                    m_moveDirection = Vector3.zero;
                }
                break;

            case DpadDirections.LEFT:
                noInput = false;
                m_animatorController.SetInteger("dir", 2);
                m_moveDirection = Vector3.Lerp(m_moveDirection, -m_playerCamera.transform.right, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * m_sMovementSpeed));
                break;

            case DpadDirections.RIGHT:
                noInput = false;
                m_animatorController.SetInteger("dir", 3);
                m_moveDirection = Vector3.Lerp(m_moveDirection, m_playerCamera.transform.right, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * m_sMovementSpeed));
                break;

            case DpadDirections.BACK:
                noInput = false;
                m_animatorController.SetInteger("dir", -1);
                m_moveDirection = Vector3.Lerp(m_moveDirection, -m_playerCamera.transform.forward, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * m_fMovementSpeed));
                break;

            case DpadDirections.NONE:
                m_dpadInput=0;
                m_animatorController.SetInteger("dir", 0);
                m_moveSpeed = Vector3.Lerp(m_moveSpeed, Vector3.zero, Mathf.Clamp(m_inertia, 0f, 1.0f));
                break;
        }
    }


    #region Combat

    void HandleCombatInputs()
    {
        if(Input.GetKeyUp(KeyCode.K))
        {

        }
    }

    #endregion

}
