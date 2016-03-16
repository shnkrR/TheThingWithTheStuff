using UnityEngine;
using System.Collections;

public class PlayerController : MonoBehaviour
{

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
    private Transform m_enemyTransform;
    private Camera m_playerCamera;
    private Vector3 m_moveDirection;
    private Vector3 m_moveSpeed;
    private bool m_isSideways;
    private float m_deafaultFSpeed;
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
//        GameObject cam = mTransform.FindChild("Main Camera").gameObject;
//        if (cam != null)
//            mPlayerCamera = cam.GetComponent<Camera>();
//        if (mPlayerCamera == null)
//            mPlayerCamera = Camera.main;
            
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
        m_enemyTransform = GameObject.Find("AI").transform;
    }
        
    void Update()
    {

#if UNITY_EDITOR

        HandleMovementInputs();
        HandleCombatInputs();

#elif UNITY_ANDROID

        HandleMovementInputs();
        HandleCombatInputs();
#endif


    }
        
    void HandleMovementInputs()
    {
        m_isSideways = false;
        noInput = true;
       
           
        if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow) || m_dpadInput==1)
        {
//            Debug.Log("W");
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
        else if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow) || m_dpadInput==-1)
        {
//            Debug.Log("S");
            noInput = false;
            m_animatorController.SetInteger("dir", -1);
            m_moveDirection = -m_playerTransform.forward;
            m_moveSpeed = ((m_moveDirection * m_fMovementSpeed));
        }
        else if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow) || m_dpadInput==2)
        {
//            Debug.Log("A");
            noInput = false;
            m_animatorController.SetInteger("dir", 2);
            m_isSideways = true;       
            m_moveDirection = -m_playerTransform.right;
            m_moveSpeed = ((m_moveDirection * m_sMovementSpeed));
        }
        else if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow) || m_dpadInput==3)
        {
//            Debug.Log("D");
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
            
        if (noInput )
        {
            m_dpadInput=0;
            m_animatorController.SetInteger("dir", 0);
            m_moveSpeed = Vector3.Lerp(m_moveSpeed, Vector3.zero, Mathf.Clamp(m_inertia, 0f, 1.0f));
        }
    }
        
    #region Dpad Inputs
    public void GoFoward()
    {
        m_dpadInput = 1;
    }

    public void OnRelease()
    {
        m_dpadInput=0;
    }

    public void GoBack()
    {
        m_dpadInput = -1;
    }

    public void GoLeft()
    {
        m_dpadInput = 2;
    }

    public void GoRight()
    {
        m_dpadInput = 3;
    }
    #endregion

    
    

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


    #region Combat

    void HandleCombatInputs()
    {
        if(Input.GetKeyUp(KeyCode.K))
        {

        }
    }

    #endregion

}
