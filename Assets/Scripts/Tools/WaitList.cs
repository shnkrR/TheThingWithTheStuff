using UnityEngine;
using System.Collections.Generic;

public class WaitList : MonoBehaviour
{
    public System.Action OnWaitListComplete;

    public List<GameObject> _WaitForObjects;

    private int mWaitCount;


    private void Start()
    {
        mWaitCount = 0;
        _WaitForObjects.TrimExcess();

        if (_WaitForObjects != null)
            mWaitCount = _WaitForObjects.Count;

        if (mWaitCount <= 0 && OnWaitListComplete != null)
            OnWaitListComplete();
    }

    public void Notify(GameObject inObject)
    {
        if (_WaitForObjects.Contains(inObject))
            mWaitCount--;

        if (mWaitCount <= 0 && OnWaitListComplete != null)
            OnWaitListComplete();
    }
}
