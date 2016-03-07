using UnityEngine;
using System.Collections;

public class Transition : MonoBehaviour 
{
    private static Transition mInstance;
    public static Transition pInstance { get { return mInstance; } }


    private void Awake()
    {
        if (Transition.pInstance == null)
            mInstance = this;
        else
        {
            Destroy(gameObject);
            return;
        }
    }

	private IEnumerator Start()
	{
        DontDestroyOnLoad(gameObject);

		yield return new WaitForSeconds (2);

		if (!string.IsNullOrEmpty (GameManager.pInstance.pLevelToLoad))
			yield return Application.LoadLevelAsync (GameManager.pInstance.pLevelToLoad);
	}

    public void RemoveLoadScreen()
    {
        mInstance = null;
        Destroy(gameObject);
    }
}
