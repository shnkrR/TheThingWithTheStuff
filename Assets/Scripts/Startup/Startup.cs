using UnityEngine;
using System.Collections;

public class Startup : MonoBehaviour 
{
	public float _StartupTime = 2.0f;

	private void Start()
	{
		Invoke ("Load", _StartupTime);
	}

	private void Load()
	{
		GameManager.pInstance.LoadGameState (GameManager.GameState.MENU);
	}
}
