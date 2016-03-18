using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class PlayerController : MonoBase
{
    //BASE MOVEMENT VARIABLES
    private float m_fMovementSpeed;
    private float m_sMovementSpeed;
    private float m_inertia;
    //
        
    //BASE COMBAT VARIABLES
    private float m_meleeDistance;
    public float p_meleeDistance { get { return m_meleeDistance; } }
    private float m_meleeAttackRate;
    private float m_meleeDamage;
    private float m_clipCapacity;
    private float m_refireRate;
    private float m_rangedDamage;
    //

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

    private float m_TurnSpeed = 5.0f;
    private float m_CurrentIdleValue;
    private float m_TimeSinceLastMeleeInput = -5.0f;
    private float m_MaxTimeForInput = 0.5f;
    private float m_MeleeCoolDown = 1.0f;

    private int m_dpadInput;
    private int m_IdlePose;
    private int m_TimesMeleeAttacked;
    private int m_LastMeleeAttackIndex = -1;

    private List<MeleeAnimData> m_MeleeAnimData = new List<MeleeAnimData>();
	private Enums.CombatState m_playerCombatState;


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
        m_animatorController.SetInteger("moveAttackIndex", 0);
        m_animatorController.SetFloat("IdlePose", 0.0f);
        m_animatorController.SetInteger("IdleTransitions", 0);
        m_animatorController.SetInteger("MeleeAttackIndex", 0);

        m_playerCamera = transform.GetComponentInChildren<Camera>(); 

        _OnObjectHeld += OnObjectHeld;

        m_IdlePose = -1;
        m_CurrentIdleValue = 0;
        m_weaponBase.m_MeleeWeapon.SetActive(false);
        m_weaponBase.m_RangeWeapon.SetActive(false);

        MeleeAnimData m = new MeleeAnimData(0.455f, 0.667f, 0.4f);
        m_MeleeAnimData.Add(m);
        m = new MeleeAnimData(0.5f, 0.667f, 0.45f);
        m_MeleeAnimData.Add(m);
        m = new MeleeAnimData(0.455f, 0.667f, 0.4f);
        m_MeleeAnimData.Add(m);
        m = new MeleeAnimData(0.5f, 0.833f, 0.455f);
        m_MeleeAnimData.Add(m);
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
		m_playerCombatState = Enums.CombatState.Melee;
		
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
        m_playerTransform.position += (m_moveSpeed * Time.deltaTime);

        m_playerTransform.LookAt(m_playerTransform.position + (m_moveSpeed));

        m_playerCamera.transform.localPosition = Vector3.zero;
        m_playerCamera.transform.LookAt(m_enemyTransform.position);
        m_playerCamera.transform.position += (m_playerCamera.transform.forward * -1.5f);
        m_playerCamera.transform.localPosition += new Vector3(0.0f, .75f, 0.0f);
//        m_playerCamera.transform.LookAt(m_enemyTransform.position);
		
        if ((m_animatorController.GetInteger("moveAttackIndex") == 0) && m_animatorController.GetInteger("dir") == 0)
            HandleDistanceTransitions();
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


        if (Input.GetKey(KeyCode.W) || m_dpadInput == 1)
        {
            moveDir = DpadDirections.FORWARD;
            Move(moveDir);
        }
        else
        if (Input.GetKey(KeyCode.S) || m_dpadInput == -1)
        {
            moveDir = DpadDirections.BACK;
            Move(moveDir);
        }
        if (Input.GetKey(KeyCode.A) || m_dpadInput == 2)
        {
            moveDir = DpadDirections.LEFT;
            Move(moveDir);
        }
        else
        if (Input.GetKey(KeyCode.D) || m_dpadInput == 3)
        {
            moveDir = DpadDirections.RIGHT;
            Move(moveDir);
        }

        Move(moveDir);
    }
    
    void Move(DpadDirections a_Direction)
    {
        if (m_animatorController.GetInteger("moveAttackIndex") > 0)
            return;

        switch (a_Direction)
        {
            case DpadDirections.FORWARD:
                noInput = false;
                m_animatorController.SetInteger("dir", 1);
                m_moveDirection = Vector3.Lerp(m_moveDirection, m_playerCamera.transform.forward, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * m_fMovementSpeed));
                
                if (m_enemyTransform != null && Vector3.Distance(m_enemyTransform.position, m_playerTransform.position) < (m_meleeDistance))
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

    void HandleDistanceTransitions()
    {
        float dist = Vector3.Distance(m_playerTransform.position, m_enemyTransform.position);
        if (dist > m_meleeDistance)
        {

			m_playerCombatState = Enums.CombatState.Ranged;
            if (m_IdlePose != 1)
            {
                m_animatorController.SetInteger("IdleTransitions", 2);
                Invoke("OnTransitionComplete", 0.5f);
                m_IdlePose = 1;
            }
        }
        else
        {
			m_playerCombatState = Enums.CombatState.Melee;
            if (m_IdlePose != 0)
            {
                m_animatorController.SetInteger("IdleTransitions", 1);
                Invoke("OnTransitionComplete", 0.5f);
                m_IdlePose = 0;
            }
        }

        m_CurrentIdleValue = Mathf.Lerp(m_CurrentIdleValue, m_IdlePose, Time.deltaTime * 10.0f);
    }

    void OnTransitionComplete()
    {
        m_weaponBase.m_MeleeWeapon.SetActive((m_IdlePose == 0) ? true : false);
        m_weaponBase.m_RangeWeapon.SetActive((m_IdlePose == 1) ? true : false);

        m_animatorController.SetFloat("IdlePose", m_CurrentIdleValue);
        m_animatorController.SetInteger("IdleTransitions", 0);
    }

    #region Combat
    void HandleCombatInputs()
    {
        if (m_animatorController.GetInteger("dir") != 0)
            return;



        if (Input.GetKeyUp(KeyCode.UpArrow) )
        {
			if(m_playerCombatState == Enums.CombatState.Melee && (m_TimesMeleeAttacked == 0) && ((Time.time - m_TimeSinceLastMeleeInput) > m_MeleeCoolDown) )
			{
				m_TimesMeleeAttacked++;
	            m_TimeSinceLastMeleeInput = Time.time;
	            m_animatorController.SetInteger("moveAttackIndex", 1);
	            m_LastMeleeAttackIndex = Random.Range(0, 3);
	            m_animatorController.SetInteger("MeleeAttackIndex", m_LastMeleeAttackIndex);
	            InvokeRepeating("TakeNextCombatInput", m_MeleeAnimData[m_LastMeleeAttackIndex].m_InputStartTime, (1.0f / 60.0f));
	            m_playerTransform.LookAt(m_enemyTransform);
	            Invoke("SendHit", m_MeleeAnimData[m_LastMeleeAttackIndex].m_HitTime); 	
        
			}

			else if (m_playerCombatState == Enums.CombatState.Ranged) 
			{
				m_animatorController.SetInteger("moveAttackIndex",0);
				
			}
    	}

		if(Input.GetKey(KeyCode.UpArrow))
		{
			if(m_playerCombatState == Enums.CombatState.Ranged)
			{
				m_playerTransform.LookAt(m_enemyTransform.position);
				m_animatorController.SetInteger("moveAttackIndex",2);     	     	
				//				m_animatorController.SetInteger("rangedMeleeIndex",0);
			}
		}
	}

    void TakeNextCombatInput()
    {
        if ((Time.time - m_TimeSinceLastMeleeInput) > (m_MeleeAnimData[m_LastMeleeAttackIndex].m_InputExpireTime))
        {
            m_TimesMeleeAttacked = 0;
            m_animatorController.SetInteger("moveAttackIndex", 0);
            m_animatorController.SetInteger("dir", 0);            
            m_LastMeleeAttackIndex = -1;
            CancelInvoke("TakeNextCombatInput");
        }
        else
        {
            if (Input.GetKeyUp(KeyCode.UpArrow))
            {
                if (m_TimesMeleeAttacked < 4)
                {
                    Debug.Log("Input");
                    m_TimesMeleeAttacked++;
                    m_TimeSinceLastMeleeInput = Time.time;
                    m_animatorController.SetInteger("moveAttackIndex", 1);
                    int rand = -1;

                    if (m_TimesMeleeAttacked != 4)
                    {
                        do
                            rand = Random.Range(0, 3);
                        while (m_LastMeleeAttackIndex == rand);
                    }
                    else
                        rand = m_LastMeleeAttackIndex = 3;

                    m_animatorController.SetInteger("MeleeAttackIndex", rand);
                    m_LastMeleeAttackIndex = rand;
                    m_playerTransform.LookAt(m_enemyTransform);
                    Invoke("SendHit", m_MeleeAnimData[m_LastMeleeAttackIndex].m_HitTime);
                    CancelInvoke("TakeNextCombatInput");
                    InvokeRepeating("TakeNextCombatInput", m_MeleeAnimData[m_LastMeleeAttackIndex].m_InputStartTime, (1.0f / 60.0f));
                }
            }
        }
    }

    void SendHit()
    {
//        if (Vector3.Distance(transform.position, _AI.position) <= m_meleeDistance)
//        {
//            Debug.Log("HIt");
//            m_animatorController.SetInteger("moveAttackIndex", 2);
//        }
    }
    #endregion

}
