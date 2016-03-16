using UnityEngine;
using System.Collections;

public class AIController : MonoBehaviour
{

    //EXPOSED BEHAVIOUR VARIABLES
    public float m_strafeDashBehaviour;
    public float m_strafeDistance;
    public float m_dashDistance;
    public float m_reactionTime;


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
        SetPlayerStats();
        SetEnemy();
        m_moveDirection = Vector3.zero;
        m_moveSpeed = Vector3.zero;
        m_animatorController = transform.GetComponent<Animator>();
        m_isSideways = false;
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

        HandleAIInputs();

    }

    void LateUpdate()
    {
        
        float oldDist = Vector3.Distance(m_playerTransform.position, m_enemyTransform.position);
        m_playerTransform.position += (m_moveSpeed * Time.deltaTime);
        
        if (m_enemyTransform != null)
            m_playerTransform.LookAt(m_enemyTransform);
        else
            m_playerTransform.LookAt(m_playerTransform.forward + new Vector3(0.0f, 0.0f, 10.0f));
        
        float newDist = Vector3.Distance(m_playerTransform.position, m_enemyTransform.position);
        
        if (m_isSideways && m_enemyTransform != null)
        {            
            float diffDist = newDist - oldDist;
            m_playerTransform.position += (m_playerTransform.forward * diffDist);
        }        
    }
    
    

    void HandleAIInputs()
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

    void MakeNewDecision()
    {
//        m_isCurrentDecisionDone=false;

        //Debug.Log("AI MAKING NEW DECISION");
        if(true)
        {
            //Debug.Log("AI GONNA MOVE");
            m_eBotState = AIState.MOVEMENT;
        }
        else if(false)
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
        int a_dashDirection = Random.Range(1,3);
        
        if (a_dashDirection == 1)
        {
            //Debug.Log("AI GONNA DASH YO ASS");
            m_movementInput = 1;            
        }
        else if(a_dashDirection==2)
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
        Invoke("MakeNewDecision",Random.Range(0f,m_reactionTime));
    }


}
