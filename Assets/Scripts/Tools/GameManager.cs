using UnityEngine;
using System.Collections;

public class GameManager : MonoBehaviour 
{
	//
	public enum GameState
	{
		START,
		LOADING,
		MENU,
		SESSION_ACTIVE,
		PAUSED,
		SESSION_END,
	}

	[System.Serializable]
	public class Levels
	{
		public string _LevelName;
		public GameState _State;
	}

	private static GameManager mInstance;
	public static GameManager pInstance { get { return mInstance; } }
    //

    //
    public System.Action pBackEvent;

    public Levels[] _Levels;

    private WaitList mCurrentLevelWaitList;

	private GameState mGameState;

	private string mLevelToLoad;
	public string pLevelToLoad { set { mLevelToLoad = value; } get { return mLevelToLoad; } }
	//

	//
	private void Awake()
	{
        if (GameManager.pInstance == null)
            mInstance = this;
        else
        {
            Destroy(gameObject);
            return;
        }

        CameraBounds.SetCamera(Camera.main);
    }

	private void Start()
	{
		DontDestroyOnLoad (gameObject);
		mGameState = GameState.START;        
	}

	private void Update()
	{
		if (Input.GetKeyDown (KeyCode.Escape))
        {
			if (pBackEvent != null)
			{
				pBackEvent();
			}
		}
	}

	private void OnLevelWasLoaded(int inLevel)
	{
		CameraBounds.SetCamera (Camera.main);

        if (Application.loadedLevelName == "Transition")
            return;

        mCurrentLevelWaitList = GameObject.FindObjectOfType<WaitList>();

        if (mCurrentLevelWaitList != null)
            mCurrentLevelWaitList.OnWaitListComplete = OnLevelWaitListComplete;
        else
            OnLevelWaitListComplete();
    }

    private void OnLevelWaitListComplete()
    {
        Transition.pInstance.RemoveLoadScreen();
    }

	public void LoadGameState(GameState inGameState)
	{
		for (int i = 0; i < _Levels.Length; i++)
		{
			if (_Levels[i]._State == inGameState)
			{
				pLevelToLoad = _Levels[i]._LevelName;
				mGameState = GameState.LOADING;
				Application.LoadLevel("Transition");
				break;
			}
		}
	}

	public void LoadLevel(string inLevel)
	{
		for (int i = 0; i < _Levels.Length; i++)
		{
			if (_Levels[i]._LevelName == inLevel)
			{
				pLevelToLoad = _Levels[i]._LevelName;
				mGameState = GameState.LOADING;
				Application.LoadLevel("Transition");
				break;
			}
		}
	}

    public void NotifyWaitComplete(GameObject inObject)
    {
        if (mCurrentLevelWaitList != null)
            mCurrentLevelWaitList.Notify(inObject);
    }

    public bool IsPaused()
    {
        return (mGameState == GameState.PAUSED);
    }

    public bool IsMobile()
    {
#if UNITY_EDITOR
        return false;
#elif UNITY_ANDROID || UNITY_IOS || UNITY_WP8
        return true;
#else
        return true;
#endif
    }
}
