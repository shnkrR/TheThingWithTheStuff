using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class PlayerController : MonoBase
{
    //BASE MOVEMENT VARIABLES
    private float m_fMovementSpeed;
    private float m_sMovementSpeed;
    private float m_inertia;
    private float m_DashSpeed;
    //
        
    //BASE COMBAT VARIABLES
    private float m_meleeDistance;
    public float p_meleeDistance { get { return m_meleeDistance; } }
    private float m_meleeAttackRate;
    private float m_meleeDamage;
    private float m_clipCapacity;
    private float m_refireRate;
    private float m_rangedDamage;
	private float m_accuracy;
    //

    private Transform m_playerTransform;    
    private Transform m_enemyTransform;
    public Transform _AI { get { return m_enemyTransform; } }

    private Camera m_playerCamera;

    private Vector3 m_PrevMoveDirection;
    private Vector3 m_moveDirection;
    private Vector3 m_moveSpeed;
    private Vector3 m_LastInVoluntaryDir;

    private RobotBase m_robotBase;

    private WeaponBase m_weaponBase;

    private Animator m_animatorController;

    private bool m_knockBack = false;
    private bool m_MeleeAttackBtnPressed = false;
	private bool m_Dash = false;

    private float m_TurnSpeed = 5.0f;
    private float m_CurrentIdleValue;
    private float m_TimeSinceLastMeleeInput = -5.0f;
    private float m_MaxTimeForInput = 0.5f;
    private float m_MeleeCoolDown = 1.0f;
    private float m_knockbackStartTime = 0.0f;
	private float m_MaxTimeBetweenDashInputs = 0.2f;
    private float m_LastDirInputTime;
    private float m_DashTime = 0.5f;
    private int m_dpadInput;
    private int m_IdlePose;
    private int m_TimesMeleeAttacked;
	private int m_TimesDirTapped;
    private int m_LastMeleeAttackIndex = -1;

	private DpadDirections m_LastDirPressed;
    private List<MeleeAnimData> m_MeleeAnimData = new List<MeleeAnimData>();
	private Enums.CombatState m_playerCombatState;

	private CombatManager m_combatManager;

    public RectTransform m_healthBar;
    private float m_healthwidth;
    private float m_MaxHealth;

    public float health { get { return m_robotBase.m_health; } }

    public bool IsBlock { get { return (m_animatorController.GetInteger("moveAttackIndex") == 4); } }

    public ParticleSystem shieldPartice;
    public ParticleSystem m_Impact;

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
		m_combatManager = new CombatManager();

        SetPlayerStats();
        SetEnemy();

        m_moveDirection = Vector3.zero;
        m_moveSpeed = Vector3.zero;

//        m_animatorController = transform.GetComponentInChildren<Animator>();
		m_animatorController = transform.GetComponent<Animator>();
        m_animatorController.SetInteger("dir", 0);
        m_animatorController.SetInteger("moveAttackIndex", 0);
        m_animatorController.SetFloat("IdlePose", 0.0f);
        m_animatorController.SetInteger("IdleTransitions", 0);
        m_animatorController.SetInteger("MeleeAttackIndex", 0);

        m_playerCamera = transform.GetComponentInChildren<Camera>(); 

        _OnObjectHeld += OnObjectHeld;
        _OnObjectReleased += OnObjectReleased;
        _OnObjectDown += OnObjectDown;

        m_IdlePose = -1;
        m_CurrentIdleValue = 0;
        m_weaponBase.m_MeleeWeapon.SetActive(false);
        m_weaponBase.m_RangeWeapon.SetActive(false);

        MeleeAnimData m = new MeleeAnimData(0.667f, 45, 67, 1.5f);
        m_MeleeAnimData.Add(m);
        m = new MeleeAnimData(0.667f, 42, 65, 1.5f);
        m_MeleeAnimData.Add(m);
        m = new MeleeAnimData(0.667f, 45, 58, 1.5f);
        m_MeleeAnimData.Add(m);
        m = new MeleeAnimData(0.833f, 41, 63, 1.5f);		
		m_MeleeAnimData.Add(m);
        m_knockBack = false;
        m_knockbackStartTime = 0.0f;

        m_playerCamera.transform.localPosition = Vector3.zero;
        m_playerCamera.transform.LookAt(m_enemyTransform.position);
        m_playerCamera.transform.position += (m_playerCamera.transform.forward * -1.5f);
        m_playerCamera.transform.localPosition += new Vector3(0.0f, .75f, 0.0f);

        m_MeleeAttackBtnPressed = false;

        m_healthwidth = m_healthBar.sizeDelta.x;
        m_MaxHealth = m_robotBase.m_health;

        shieldPartice.Stop(true);
        m_Impact.Stop(true);
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
		m_accuracy = m_weaponBase.m_accuracy;
		m_playerCombatState = Enums.CombatState.Melee;
		
		m_DashSpeed = m_robotBase.m_dashspeed;
    }

    void SetEnemy()
    {
        m_enemyTransform = GameObject.Find("AI").transform;
    }

    #region Unity Functions
    protected override void Update()
    {
        base.Update();

		if (!m_Dash)
        {
            HandleMovementInputs();
            HandleCombatInputs();
        }
        else
        {
            Move(m_LastDirPressed);
        }

        float healthNormalized = m_robotBase.m_health / m_MaxHealth;
        float width = healthNormalized * m_healthwidth;
        Rect rect = m_healthBar.rect;
        rect.width = width;
        m_healthBar.sizeDelta = new Vector2(width, m_healthBar.sizeDelta.y);

        m_robotBase.m_health = Mathf.Clamp(m_robotBase.m_health, 0.0f, m_MaxHealth);
    }

    void FixedUpdate()
    {
        m_dpadInput = 0;
    }

    void OnDestroy()
    {
        _OnObjectHeld -= OnObjectHeld;
        _OnObjectReleased -= OnObjectReleased;
        _OnObjectDown -= OnObjectDown;
    }

	private bool m_DirChangeAbrupt = false;
    void LateUpdate()
    {
        Vector3 prev = m_playerTransform.position;

        if (!m_DirChangeAbrupt)
        {
            m_playerTransform.position += (m_moveSpeed * Time.deltaTime);
        }

        if ((Vector3.Distance(Vector3.zero, transform.position) > World.WorldRadius))
        {
            float diff = Vector3.Distance(prev, m_playerTransform.position);
            m_playerTransform.position += (m_playerCamera.transform.forward * diff);
        }

        if (!m_knockBack)
        {
            if (m_animatorController.GetInteger("moveAttackIndex") == 0)
            {
                if (m_DirChangeAbrupt)
                {
                    m_DirChangeAbrupt = false;
                    m_inertia = m_robotBase.m_inertia;
                    m_moveSpeed = Vector3.zero;
                }

                if (!m_Dash)
                    m_playerTransform.LookAt(m_playerTransform.position + (m_moveSpeed));
                else
                {
                    m_playerTransform.eulerAngles = m_playerCamera.transform.eulerAngles;
                }
            }
            else
            {
                m_playerTransform.LookAt(m_enemyTransform);
                m_moveSpeed = m_playerTransform.forward;
                m_DirChangeAbrupt = true;
                m_inertia = 1.0f;
                //Debug.Log(m_playerTransform);
            }
        }
        else
            m_playerTransform.LookAt(m_playerTransform.position - (m_moveSpeed));

        m_playerCamera.transform.localPosition = Vector3.zero;
        m_playerCamera.transform.LookAt(m_enemyTransform.position);
        m_playerCamera.transform.position += (m_playerCamera.transform.forward * -1.5f);
        m_playerCamera.transform.localPosition += new Vector3(0.0f, .75f, 0.0f);

		
        if ((m_animatorController.GetInteger("moveAttackIndex") == 0) && m_animatorController.GetInteger("dir") == 0 && !m_knockBack)
            HandleDistanceTransitions();
    }
    #endregion

    #region System Events
    void OnObjectHeld(Object a_Object)
    {
        GameObject go = (GameObject)a_Object;

        if (m_Dash)
            return;
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
            else if (go.name == "Button_Attack")
            {
                if (m_playerCombatState == Enums.CombatState.Ranged)
                {
                    m_playerTransform.LookAt(m_enemyTransform.position);
                    m_animatorController.SetInteger("moveAttackIndex", 2);
                }
                else if (m_playerCombatState == Enums.CombatState.Melee)
                    m_MeleeAttackBtnPressed = false;
            }
            else if (go.name == "Button_Block")
            {
                m_animatorController.SetInteger("moveAttackIndex", 4);

                if (!shieldPartice.isPlaying)
                    shieldPartice.Play(true);
            }
        }
    }

    void OnObjectReleased(Object a_Object)
    {
        GameObject go = (GameObject)a_Object;

        if (m_Dash)
            return;
        if (go != null)
        {
			if (go.name == "DPad_Up")
            {
                if (m_TimesDirTapped == 0)
                    m_LastDirPressed = DpadDirections.FORWARD;

                if (m_LastDirPressed == DpadDirections.FORWARD && ((Time.time - m_LastDirInputTime) < m_MaxTimeBetweenDashInputs))
                {
                    m_TimesDirTapped++;
                    m_LastDirPressed = DpadDirections.FORWARD;

                    if (m_TimesDirTapped == 4)
                        m_Dash = true;
                }
                else
                {
                    m_LastDirPressed = DpadDirections.NONE;
                    m_TimesDirTapped = 0;
                    m_Dash = false;
                }
            }
            else if (go.name == "DPad_Down")
            {
                if (m_TimesDirTapped == 0)
                    m_LastDirPressed = DpadDirections.BACK;

                if (m_LastDirPressed == DpadDirections.BACK && ((Time.time - m_LastDirInputTime) < m_MaxTimeBetweenDashInputs))
                {
                    m_TimesDirTapped++;
                    m_LastDirPressed = DpadDirections.BACK;

                    if (m_TimesDirTapped == 4)
                        m_Dash = true;
                }
                else
                {
                    m_LastDirPressed = DpadDirections.NONE;
                    m_TimesDirTapped = 0;
                    m_Dash = false;
                }
            }
            else if (go.name == "DPad_Left")
            {
                if (m_TimesDirTapped == 0)
                    m_LastDirPressed = DpadDirections.LEFT;

                if (m_LastDirPressed == DpadDirections.LEFT && ((Time.time - m_LastDirInputTime) < m_MaxTimeBetweenDashInputs))
                {
                    m_TimesDirTapped++;
                    m_LastDirPressed = DpadDirections.LEFT;

                    if (m_TimesDirTapped == 4)
                        m_Dash = true;
                }
                else
                {
                    m_LastDirPressed = DpadDirections.NONE;
                    m_TimesDirTapped = 0;
                    m_Dash = false;
                }
            }
            else if (go.name == "DPad_Right")
            {
                if (m_TimesDirTapped == 0)
                    m_LastDirPressed = DpadDirections.RIGHT;

                if (m_LastDirPressed == DpadDirections.RIGHT && ((Time.time - m_LastDirInputTime) < m_MaxTimeBetweenDashInputs))
                {
                    m_TimesDirTapped++;
                    m_LastDirPressed = DpadDirections.RIGHT;

                    if (m_TimesDirTapped == 4)
                        m_Dash = true;
                }
                else
                {
                    m_LastDirPressed = DpadDirections.NONE;
                    m_TimesDirTapped = 0;
                    m_Dash = false;
                }
            }
            else
            if (go.name == "Button_Attack")
            {
                if (m_playerCombatState == Enums.CombatState.Ranged)
                {
                    m_animatorController.SetInteger("moveAttackIndex", 0);
                }
                else if (m_playerCombatState == Enums.CombatState.Melee)
                {
                    m_MeleeAttackBtnPressed = false;
                }
            }
            else if (go.name == "Button_Block")
            {
                m_animatorController.SetInteger("moveAttackIndex", 0);
                shieldPartice.Stop(true);
            }
            if(m_Dash)
            {
                Invoke("EndDash", m_DashTime);
            }
        }
    }

    void OnObjectDown(Object a_Object)
    {
        GameObject go = (GameObject)a_Object;

        if (m_Dash)
            return;
        if (go != null)
        {
            if (go.name == "DPad_Up")
            {
                m_LastDirInputTime = Time.time;
                m_dpadInput = 1;                
            }
            else if (go.name == "DPad_Down")
            {
                m_LastDirInputTime = Time.time;
                m_dpadInput = -1;
            }
            else if (go.name == "DPad_Left")
            {
                m_LastDirInputTime = Time.time;
                m_dpadInput = 2;
            }
            else if (go.name == "DPad_Right")
            {
                m_LastDirInputTime = Time.time;
                m_dpadInput = 3;
            }
            else
            if (go.name == "Button_Attack")
            {
                if (m_playerCombatState == Enums.CombatState.Melee)
                {
                    if (m_TimesMeleeAttacked == 0 && ((Time.time - m_TimeSinceLastMeleeInput) > m_MeleeCoolDown))
                    {
                        m_TimesMeleeAttacked++;
                        m_TimeSinceLastMeleeInput = Time.time;
                        m_animatorController.SetInteger("moveAttackIndex", 1);
                        m_LastMeleeAttackIndex = Random.Range(0, 3);
                        m_animatorController.SetInteger("MeleeAttackIndex", m_LastMeleeAttackIndex);
                        InvokeRepeating("TakeNextCombatInput", m_MeleeAnimData[m_LastMeleeAttackIndex].m_InputStartTime, (1.0f / 60.0f));
                        m_playerTransform.LookAt(m_enemyTransform.position);
                        Invoke("SendHit", m_MeleeAnimData[m_LastMeleeAttackIndex].m_HitTime);
                    }
                    else
                    {
                        m_MeleeAttackBtnPressed = true;
                    }
                }
            }
        }
    }
    #endregion
        
    void HandleMovementInputs()
    {
        if (!m_knockBack)
        {
            DpadDirections moveDir = DpadDirections.NONE;

            if (Input.GetKey(KeyCode.W) || m_dpadInput == 1)
            {
                moveDir = DpadDirections.FORWARD;
                Move(moveDir);
            }
            else if (Input.GetKey(KeyCode.S) || m_dpadInput == -1)
            {
                moveDir = DpadDirections.BACK;
                Move(moveDir);
            }

            if (Input.GetKey(KeyCode.A) || m_dpadInput == 2)
            {
                moveDir = DpadDirections.LEFT;
                Move(moveDir);
            }
            else if (Input.GetKey(KeyCode.D) || m_dpadInput == 3)
            {
                moveDir = DpadDirections.RIGHT;
                Move(moveDir);
            }

            Move(moveDir);
        }
        else
        {
            if ((Time.time - m_knockbackStartTime) < m_robotBase.m_knockBackTime)
            {
                m_moveDirection = -m_playerCamera.transform.forward;
                m_moveSpeed = ((m_moveDirection * m_robotBase.m_knockbackSpeed));
            }
            else
                m_knockBack = false;
        }
    }
    void EndDash()
    {
        m_LastDirPressed = DpadDirections.NONE;
        m_TimesDirTapped = 0;
        m_Dash = false;

        m_moveSpeed = m_playerTransform.forward;
        m_DirChangeAbrupt = true;
        m_inertia = 1.0f;
    }
    
    void Move(DpadDirections a_Direction)
    {
        Transform sourceTrans = m_playerCamera.transform;

        if (a_Direction != DpadDirections.NONE && m_animatorController.GetInteger("moveAttackIndex") != 0)
            return;

        switch (a_Direction)
        {
            case DpadDirections.FORWARD:
                m_animatorController.SetInteger("dir", 1);
                m_moveDirection = Vector3.Lerp(m_moveDirection, sourceTrans.forward, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * (m_fMovementSpeed + (m_Dash ? m_DashSpeed : 0) )));
                
                if (m_enemyTransform != null && Vector3.Distance(m_enemyTransform.position, m_playerTransform.position) < (m_meleeDistance))
                {
                    m_moveSpeed = Vector3.zero;
                    m_moveDirection = Vector3.zero;
                }
                break;

            case DpadDirections.LEFT:
                m_animatorController.SetInteger("dir", (m_Dash) ? 2 : 1);
                m_moveDirection = Vector3.Lerp(m_moveDirection, -sourceTrans.right, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * (m_sMovementSpeed + (m_Dash ? m_DashSpeed : 0) )));
                break;

            case DpadDirections.RIGHT:
                m_animatorController.SetInteger("dir", (m_Dash) ? 3 : 1);
                m_moveDirection = Vector3.Lerp(m_moveDirection, sourceTrans.right, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * (m_sMovementSpeed + (m_Dash ? m_DashSpeed : 0) )));
                break;

            case DpadDirections.BACK:
                m_animatorController.SetInteger("dir", (m_Dash) ? -1 : 1);
                m_moveDirection = Vector3.Lerp(m_moveDirection, -sourceTrans.forward, Time.deltaTime * m_TurnSpeed);
                m_moveSpeed = ((m_moveDirection * (m_fMovementSpeed + (m_Dash ? m_DashSpeed : 0) )));
                break;

            case DpadDirections.NONE:
                m_dpadInput=0;
                m_animatorController.SetInteger("dir", 0);
				if (!m_DirChangeAbrupt)
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
        if (m_animatorController.GetInteger("dir") != 0 || m_knockBack)
            return;

        if (Input.GetKey(KeyCode.Space))
        {
            m_animatorController.SetInteger("moveAttackIndex", 4);
        }
        else if (Input.GetKeyUp(KeyCode.Space))
        {
            m_animatorController.SetInteger("moveAttackIndex", 0);
        }

        if (Input.GetKeyUp(KeyCode.UpArrow))
        {
			if (m_playerCombatState == Enums.CombatState.Ranged) 
			{
				m_animatorController.CrossFade ("range_attack",0f);
				m_animatorController.SetInteger("moveAttackIndex",0);	
			}
    	}

		if (Input.GetKey(KeyCode.UpArrow))
		{
			if(m_playerCombatState == Enums.CombatState.Ranged)
			{
				m_playerTransform.LookAt(m_enemyTransform.position);
				m_animatorController.SetInteger("moveAttackIndex",2);     	     	
			}
		}

        if (Input.GetKeyDown(KeyCode.UpArrow))
        {
            if (m_playerCombatState == Enums.CombatState.Melee && (m_TimesMeleeAttacked == 0) && ((Time.time - m_TimeSinceLastMeleeInput) > m_MeleeCoolDown))
            {
                m_TimesMeleeAttacked++;
                m_TimeSinceLastMeleeInput = Time.time;
                m_animatorController.SetInteger("moveAttackIndex", 1);
                m_LastMeleeAttackIndex = Random.Range(0, 3);
                m_animatorController.SetInteger("MeleeAttackIndex", m_LastMeleeAttackIndex);
                InvokeRepeating("TakeNextCombatInput", m_MeleeAnimData[m_LastMeleeAttackIndex].m_InputStartTime, (1.0f / 60.0f));
                m_playerTransform.LookAt(m_enemyTransform.position);
                Invoke("SendHit", m_MeleeAnimData[m_LastMeleeAttackIndex].m_HitTime);
            }
        }



	}

    void TakeNextCombatInput()
    {
        if (m_LastMeleeAttackIndex == -1)
            return;

        if ((Time.time - m_TimeSinceLastMeleeInput) > (m_MeleeAnimData[m_LastMeleeAttackIndex].m_InputExpireTime))
        {
            m_TimesMeleeAttacked = 0;
            m_animatorController.SetInteger("moveAttackIndex", 0);
            m_animatorController.SetInteger("dir", 0);
            m_animatorController.SetInteger("MeleeAttackIndex", -1);
            if (m_LastMeleeAttackIndex == 3)
                m_TimeSinceLastMeleeInput = Time.time;
            m_LastMeleeAttackIndex = -1;
            CancelInvoke("TakeNextCombatInput");
        }
        else
        {
            if (Input.GetKeyDown(KeyCode.UpArrow) || m_MeleeAttackBtnPressed)
            {
                if (m_TimesMeleeAttacked < 4)
                {
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
        float damage = m_meleeDamage;

        if (m_enemyTransform.GetComponent<AIController>().IsBlock)
            damage /= 4.0f;

        m_enemyTransform.GetComponent<RobotBase>().m_health = m_combatManager.DealMeleeDamage(m_enemyTransform.GetComponent<RobotBase>().m_health, damage);
        m_enemyTransform.GetComponent<AIController>().RecieveHit((m_TimesMeleeAttacked == 4));
    }

    public void RecieveHit(bool knockBack)
    {
        if (m_playerCombatState == Enums.CombatState.Melee)
        {
            m_animatorController.SetInteger("moveAttackIndex", 0);
            m_animatorController.SetInteger("moveAttackIndex", 3);
            m_animatorController.SetInteger("MeleeAttackIndex", -1);
            CancelInvoke("TakeNextCombatInput");
            CancelInvoke("Recover");
            Invoke("Recover", 0.667f);
            m_knockBack = knockBack;
            m_knockbackStartTime = Time.time;
            m_Impact.Play(true);
        }
    }

    void Recover()
    {
        m_Impact.Stop(true);
        m_TimesMeleeAttacked = 0;
        m_animatorController.SetInteger("moveAttackIndex", 0);
        m_animatorController.SetInteger("dir", 0);
        m_animatorController.SetInteger("MeleeAttackIndex", -1);
        m_LastMeleeAttackIndex = -1;
    }
    #endregion



	#region ANIMATION EVENTS
	public void DoRangedDamage()
	{
        float damage = m_rangedDamage;

        if (m_enemyTransform.GetComponent<AIController>().IsBlock)
            damage /= 4.0f;

		ShowRangedVFX();
        m_enemyTransform.GetComponent<AIController>().m_Impact.Play(true);
        m_enemyTransform.GetComponent<RobotBase>().m_health = m_combatManager.DealRangedDamage(m_enemyTransform.GetComponent<RobotBase>().m_health, m_accuracy, damage);
        Invoke("StopParticle", 0.5f);
	}

    void StopParticle()
    {
        m_enemyTransform.GetComponent<AIController>().m_Impact.Stop(true);
    }

	public void ShowRangedVFX()
	{
		GameObject a_bullet = GameObject.Instantiate (m_weaponBase.m_rangedBullet);
		a_bullet.SetActive(true);
		a_bullet.transform.position = m_weaponBase.m_rangedBullet.transform.position;
		a_bullet.transform.rotation = m_weaponBase.m_rangedBullet.transform.rotation;
		a_bullet.GetComponent<Rigidbody>().AddForce((m_enemyTransform.position+new Vector3(0,1f,0) - a_bullet.transform.position) *1000f);
		StartCoroutine(DestroyGameObject(a_bullet, 1f));
		

	}

	#endregion



	IEnumerator DestroyGameObject(GameObject _obj, float _delayTime)
	{
		yield return new WaitForSeconds(_delayTime);
		Destroy(_obj);
	}


}
