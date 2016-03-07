using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;


[System.Serializable]
public class MenuScreen
{
    public string _ScreenID;

    public GameObject[] _ScreenObjects;
    public GameObject _BackButton;

    private int mScreenIndex;
    public int pScreenIndex { set { mScreenIndex = value; } get { return mScreenIndex; } }
}

public class MenuHandler : MonoBehaviour 
{
    public MenuScreen[] _MenuScreens;

    private MenuScreen mCurrentMenuScreen;


	private void Start()
	{
        for (int i = 0; i < _MenuScreens.Length; i++)
        {
            _MenuScreens[i].pScreenIndex = i;
            for (int j = 0; j < _MenuScreens[i]._ScreenObjects.Length; j++)
                _MenuScreens[i]._ScreenObjects[j].SetActive(false);
        }

        mCurrentMenuScreen = _MenuScreens[0];
        GoToScreen(0);
    }

	private void Update()
	{
	}

    private void OnEnable()
    {
        GameManager.pInstance.pBackEvent += OnPressBackButton;
    }

    private void OnDisable()
    {
        GameManager.pInstance.pBackEvent -= OnPressBackButton;
    }

    private void OnPressBackButton()
    {
        if (mCurrentMenuScreen.pScreenIndex > 0)
            GoToScreen(mCurrentMenuScreen.pScreenIndex - 1);
    }

    public void GoToScreen(string inScreenID)
    {
        for (int i = 0; i < mCurrentMenuScreen._ScreenObjects.Length; i++)
            mCurrentMenuScreen._ScreenObjects[i].SetActive(false);

        for (int i = 0; i < _MenuScreens.Length; i++)
        {
            if (_MenuScreens[i]._ScreenID == inScreenID)
            {
                mCurrentMenuScreen = _MenuScreens[i];
                break;
            }
        }

        for (int i = 0; i < mCurrentMenuScreen._ScreenObjects.Length; i++)
            mCurrentMenuScreen._ScreenObjects[i].SetActive(true);
    }

    public void GoToScreen(int inScreenIndex)
    {
        for (int i = 0; i < mCurrentMenuScreen._ScreenObjects.Length; i++)
            mCurrentMenuScreen._ScreenObjects[i].SetActive(false);

        mCurrentMenuScreen = _MenuScreens[inScreenIndex];

        for (int i = 0; i < mCurrentMenuScreen._ScreenObjects.Length; i++)
            mCurrentMenuScreen._ScreenObjects[i].SetActive(true);
    }

    #region Callbacks
    public void OnClick(UIBehaviour inUIObject)
	{
        switch (inUIObject.name)
        {
            case "Play":
                GameManager.pInstance.LoadGameState(GameManager.GameState.SESSION_ACTIVE);
                break;

            case "Options":
                GoToScreen("Options");
                break;

            case "Options_Back":
                GoToScreen("Main Menu");
                break;
        }
	}
	#endregion
}
