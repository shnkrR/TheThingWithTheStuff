using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class AIController : MonoBehaviour
{

    //EXPOSED BEHAVIOUR VARIABLES
    public float m_strafeDashBehaviour;
    public float m_strafeDistance;
    public float m_dashDistance;
    public float m_reactionTime;
	public float m_aggression;
	public float m_chargeTendency;
	public float m_blockTendency;


    //BASE MOVEMENT VARIABLES
    private float m_fMovementSpeed;
    private float m_sMovementSpeed;
    private float m_inertia;
    
    //BASE COMBAT VARIABLES
    private float m_meleeDistance;
    private float m_meleeAttackRate;
    private float m_meleeDamage;
    private float m_clipCapacity;
    private float m_refireRate;
    private float m_rangedDamage;
	private float m_accuracy;
	

    private Transform m_playerTransform;
    public Transform m_enemyTransform;
    private Vector3 m_moveDirection;
    private Vector3 m_moveSpeed;
    private bool m_isSideways;
    private float m_deafaultFSpeed;
    private RobotBase m_robotBase;
    private WeaponBase m_weaponBase;
    private Animator m_animatorController;
    private AIState m_eBotState = AIState.MOVEMENT;
    private bool m_isCurrentDecisionDone=true;
    private int m_movementInput=10;
	private int m_combatInput=10;
	private int m_blockInput=10;
    private bool m_knockBack = false;

    private int m_IdlePose;
    private float m_CurrentIdleValue;
	private int m_TimesMeleeAttacked;
	private int m_LastMeleeAttackIndex = -1;
	private float m_TimeSinceLastMeleeInput = -5.0f;

	private float m_MaxTimeForInput = 0.5f;
	private float m_MeleeCoolDown = 1.0f;
	private float m_knockbackStartTime = 0.0f;

	private List<MeleeAnimData> m_MeleeAnimData = new List<MeleeAnimData>();
	private bool m_MeleeAttackBtnPressed = false;
	private CombatManager m_combatManager;
    
	

	private Enums.CombatState m_playerCombatState = Enums.CombatState.Ranged;
	

    enum AIState
    {
        NONE=0,
        COMBAT,
        MOVEMENT
    }

    void Start()
    {
        Initialise();
        MakeNewDecision();
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
        m_animatorController = transform.GetComponentInChildren<Animator>();
        m_isSideways = false;
        m_IdlePose = -1;
        m_CurrentIdleValue = 0;

		m_animatorController = transform.GetComponent<Animator>();
		m_animatorController.SetInteger("dir", 0);
		m_animatorController.SetInteger("moveAttackIndex", 0);
		m_animatorController.SetFloat("IdlePose", 0.0f);
		m_animatorController.SetInteger("IdleTransitions", 0);
		m_animatorController.SetInteger("MeleeAttackIndex", 0);
        
		m_MeleeAnimData.Add(new MeleeAnimData(0.455f, 0.667f, 0.4f));
		m_MeleeAnimData.Add(new MeleeAnimData(0.5f, 0.667f, 0.45f));
		m_MeleeAnimData.Add(new MeleeAnimData(0.455f, 0.667f, 0.4f));
		m_MeleeAnimData.Add(new MeleeAnimData(0.5f, 0.833f, 0.455f));
		m_knockBack = false;
		m_knockbackStartTime = 0.0f;

        m_MeleeAttackBtnPressed = false;
		
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
		
    }

    void SetEnemy()
    {
        m_enemyTransform = GameObject.Find("Player").transform;        
    }
        
    void Update()
    {
//        if(m_isCurrentDecisionDone == true)
//        {
//            Invoke("MakeNewDecision",m_reactionTime);
//        }
//        else if(m_isCurrentDecisionDone == false)
//        {
//            DoCurrentDecision();
//        }

        HandleAIMovementInputs();
		HandleAICombatInputs();
    }

    void LateUpdate()
    {        
        //float oldDist = Vector3.Distance(m_playerTransform.position, m_enemyTransform.position);

        Vector3 prev = m_playerTransform.position;
        m_playerTransform.position += (m_moveSpeed * Time.deltaTime);

        if (Vector3.Distance(Vector3.zero, transform.position) > World.WorldRadius)
            m_playerTransform.position = prev;
        
        if (m_enemyTransform != null)
            m_playerTransform.LookAt(m_enemyTransform);
        else
            m_playerTransform.LookAt(m_playerTransform.forward + new Vector3(0.0f, 0.0f, 10.0f));
        
        //float newDist = Vector3.Distance(m_playerTransform.position, m_enemyTransform.position);
        
        //if (m_isSideways && m_enemyTransform != null)
        //{            
        //    float diffDist = newDist - oldDist;
        //    m_playerTransform.position += (m_playerTransform.forward * diffDist);
        //}        

//		if (!m_knockBack)
//		{
//			if (m_animatorController.GetInteger("moveAttackIndex") == 0)
//			{
//				m_playerTransform.LookAt(m_playerTransform.position + (m_moveSpeed));
//			}
//			else
//			{
//				m_playerTransform.LookAt(m_enemyTransform);
//			}
//		}
//		else
//			m_playerTransform.LookAt(m_playerTransform.position - (m_moveSpeed));

		if ((m_animatorController.GetInteger("moveAttackIndex") == 0) && m_animatorController.GetInteger("dir") == 0 && !m_knockBack)
			HandleDistanceTransitions();
    }
    
    
    
    void HandleAIMovementInputs()
    {
		if (!m_knockBack)
		{
	        bool noInput = true;
	        m_isSideways = false;
	        
	        if (m_movementInput == 1)
	        {
	//            Debug.Log("MOVING FORWARD");
	            noInput = false;
	            m_animatorController.SetInteger("dir", 1);
	            m_moveDirection = m_playerTransform.forward;
	            m_moveSpeed = ((m_moveDirection * m_fMovementSpeed));
	            
	            if (m_enemyTransform != null && Vector3.Distance(m_enemyTransform.position, m_playerTransform.position) < m_meleeDistance)
	            {
	                noInput = true;
	                m_moveSpeed = Vector3.zero;
	                m_moveDirection = Vector3.zero;
	            }
	        }
	        else if (m_movementInput == -1)
	        {
	//            Debug.Log("MOVING BACKWARD");
	            noInput = false;
	            m_animatorController.SetInteger("dir", -1);
	            m_moveDirection = -m_playerTransform.forward;
	            m_moveSpeed = ((m_moveDirection * m_fMovementSpeed));
	        }
	        else if (m_movementInput == 2)
	        {
	//            Debug.Log("MOVING LEFT");
	            noInput = false;
	            m_animatorController.SetInteger("dir", 2);
	            m_isSideways = true;       
	            m_moveDirection = -m_playerTransform.right;
	            m_moveSpeed = ((m_moveDirection * m_sMovementSpeed));
	        }
	        else if (m_movementInput == 3)
	        {
	//            Debug.Log("MOVING RIGHT");
	            noInput = false;
	            m_animatorController.SetInteger("dir", 3);
	            m_isSideways = true;
	            m_moveDirection = m_playerTransform.right;
	            m_moveSpeed = ((m_moveDirection * m_sMovementSpeed));
	        }
	        else
	        {
	            m_animatorController.SetInteger("dir", 0);            
	        }
	        
	        if (noInput)
	        {
	            m_animatorController.SetInteger("dir", 0);
	            m_moveSpeed = Vector3.Lerp(m_moveSpeed, Vector3.zero, Mathf.Clamp(m_inertia, 0f, 1.0f));
	        }
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
	void HandleAICombatInputs()
	{
		if (m_animatorController.GetInteger("dir") != 0 || m_knockBack)
			return;
		
		if (m_blockInput==1)
		{
			m_animatorController.SetInteger("moveAttackIndex", 4);
		}

		
		if (m_combatInput==0)//(Input.GetKeyUp(KeyCode.UpArrow))
		{
			if (m_playerCombatState == Enums.CombatState.Ranged) 
			{
				m_animatorController.CrossFade ("range_attack",0f);
				m_animatorController.SetInteger("moveAttackIndex",0);	
			}
		}
		
		if (m_combatInput==1)//(Input.GetKey(KeyCode.UpArrow))
		{
			if(m_playerCombatState == Enums.CombatState.Ranged)
			{
				m_playerTransform.LookAt(m_enemyTransform.position);
				m_animatorController.SetInteger("moveAttackIndex",2);     	     	
			}
		}
		
		if (m_combatInput==0)//(Input.GetKeyDown(KeyCode.UpArrow))
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
			if (m_combatInput==0)//(Input.GetKeyDown(KeyCode.UpArrow) || m_MeleeAttackBtnPressed)
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
		Debug.Log("MELEE HIT BY AI");
		m_enemyTransform.GetComponent<RobotBase>().m_health = m_combatManager.DealMeleeDamage(m_enemyTransform.GetComponent<RobotBase>().m_health, m_meleeDamage);
		Debug.Log("Player Health = "+ m_enemyTransform.GetComponent<RobotBase>().m_health);
	}
	
	void RecieveHit(bool knockBack)
	{
		if (m_playerCombatState == Enums.CombatState.Melee)
		{
			m_animatorController.SetInteger("moveAttackIndex", 3);
			m_animatorController.SetInteger("MeleeAttackIndex", -1);
			CancelInvoke("TakeNextCombatInput");
			Invoke("Recover", 0.667f);
			m_knockBack = knockBack;
			m_knockbackStartTime = Time.time;
		}
	}
	
	void Recover()
	{
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
		Debug.Log("RANGED HIT BY AI");
		ShowRangedVFX();
		m_enemyTransform.GetComponent<RobotBase>().m_health = m_combatManager.DealRangedDamage(m_enemyTransform.GetComponent<RobotBase>().m_health, m_accuracy, m_rangedDamage);
		Debug.Log("Player Health = "+ m_enemyTransform.GetComponent<RobotBase>().m_health);
		
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
    
    void MakeNewDecision()
    {
        //        m_isCurrentDecisionDone=false;
        
        //Debug.Log("AI MAKING NEW DECISION");

		float a_movementOrCombat = Random.Range(0.0f,1f);

        if(a_movementOrCombat >=m_aggression)
        {
            //Debug.Log("AI GONNA MOVE");
            m_eBotState = AIState.MOVEMENT;
        }
        else if(a_movementOrCombat < m_aggression)
        {
            //Debug.Log("AI GONNA ATTACK YO ASS");
            m_eBotState = AIState.COMBAT;
            
        }
        
        DoCurrentDecision();
    }
    
    void DoCurrentDecision()
    {
        if(m_eBotState == AIState.MOVEMENT)
        {
            MovementDecision();
        }
        else if (m_eBotState == AIState.COMBAT)
        {            
            CombatDecision();
        }
    }
    void MovementDecision()
    {
        
        float a_strafeOrDashDecider = Random.Range(0.0f,1f);
        
        if(a_strafeOrDashDecider >=m_strafeDashBehaviour)
        {
            //Debug.Log("AI GONNA STRAFE");
            Strafe();
            
        }
        else if(a_strafeOrDashDecider < m_strafeDashBehaviour)
        {
            //Debug.Log("AI GONNA DASH");
            Dash();
        }
        
    }
    
    void CombatDecision()
    {
		float a_blockOrHitDecider = Random.Range(0.0f,1f);
		
		if(a_blockOrHitDecider <=m_blockTendency)
		{
			//Debug.Log("AI GONNA STRAFE");
			Block();
			
		}
		else if(a_blockOrHitDecider > m_blockTendency)
		{
			//Debug.Log("AI GONNA DASH");
			Hit();
		}
    }
    
	void Block()
	{
		float a_blockTime = Random.Range(0,3);
		m_blockInput = 1;

		Invoke("DecisionCompleted",a_blockTime);

	}
	void Hit()
	{
		float a_hitTime = Random.Range(0,3);
		m_combatInput = 0;
		
		Invoke("DecisionCompleted",a_hitTime);
	}

    void Strafe()
    {
        float a_strafeTime = Random.Range(0,m_strafeDistance);
        int a_strafeDirection = Random.Range(1,3);
        
        if(a_strafeDirection == 1)
        {
           // Debug.Log("AI GONNA STRAFE TO THE LEFT");
            m_movementInput = 2;
        }
        else if (a_strafeDirection == 2)
        {            
            //Debug.Log("AI GONNA STRAFE TO THE RIGHT");
            m_movementInput =3;
        }
        
        Invoke("DecisionCompleted",a_strafeTime);
        
    }
    
    void Dash()
    {
        float a_dashTime = Random.Range(0,m_dashDistance);
//        int a_dashDirection = Random.Range(1,3);
		float a_dashDirection = Random.Range(0,1);
        
        if (a_dashDirection< m_chargeTendency)//(a_dashDirection == 1)
        {
            //Debug.Log("AI GONNA DASH YO ASS");
            m_movementInput = 1;            
        }
        else if (a_dashDirection>= m_chargeTendency)//(a_dashDirection==2)
        {
            //Debug.Log("AI GONNA RUN AWAY LIKE A SISSY");
            m_movementInput = -1;            
        }
        
        Invoke("DecisionCompleted",a_dashTime);
    }
    
    void DecisionCompleted()
    {
        //Debug.Log("THIS AI G HAS DONE WHAT IT WANTS GONNA DECIDE WHAT TO DO NOW");
        m_movementInput=10;
		m_combatInput = 10;
		m_blockInput = 10;
		m_animatorController.SetInteger("moveAttackIndex", 0);
        Invoke("MakeNewDecision",Random.Range(0f,m_reactionTime));
    }
}
