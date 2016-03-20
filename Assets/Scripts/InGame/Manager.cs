using UnityEngine;
using System.Collections;

public class Manager : MonoBehaviour 
{
    public PlayerController m_PC;
    public AIController mAIC;

    public GameObject gameOverScreen;


    void Start()
    {
        gameOverScreen.SetActive(false);
    }

    void Update()
    {
        if (m_PC.health <= 0 || mAIC.health <= 0)
        {
            gameOverScreen.SetActive(true);

            if (Input.GetMouseButtonDown(0))
            {
                if (GameManager.pInstance != null)
                    GameManager.pInstance.LoadGameState(GameManager.GameState.MENU);
                else
                    Application.LoadLevel("test");
            }
        }
    }
}
