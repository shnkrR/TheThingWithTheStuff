using UnityEngine;
using System.Collections;

public class ObjectPool 
{
    public class PoolObject
    {
        public GameObject _Object;
        public bool _Used = false;
    }

    private PoolObject[] mPoolObjects;
    public PoolObject[] pPoolObjects { get { return mPoolObjects; } }

    public ObjectPool(GameObject inPoolObject, int inPoolSize = 10)
    {
        if (inPoolObject)
        {
            GameObject parent = new GameObject("Pool_" + inPoolObject.name);
            parent.transform.position = Vector3.zero;

            mPoolObjects = new PoolObject[inPoolSize];
            for (int i = 0; i < inPoolSize; i++)
            {
                mPoolObjects[i] = new PoolObject();
                mPoolObjects[i]._Object = GameObject.Instantiate(inPoolObject);
                mPoolObjects[i]._Object.name = "PoolObj_" + inPoolObject.name + "_" + i;
                mPoolObjects[i]._Object.transform.parent = parent.transform;
                mPoolObjects[i]._Object.transform.localPosition = Vector3.zero;
                mPoolObjects[i]._Object.SetActive(false);
                mPoolObjects[i]._Used = false;
            }
        }
        else
            Debug.LogError("PoolObject is null");
    }

    public GameObject GetFreeObject()
    {
        for (int i = 0; i < mPoolObjects.Length; i++)
        {
            if (!mPoolObjects[i]._Used)
            {
                mPoolObjects[i]._Used = true;
                mPoolObjects[i]._Object.SetActive(true);
                return mPoolObjects[i]._Object;
            }
        }

        return null;
    }

    public void Destroy(GameObject inGameObject)
    {
        for (int i = 0; i < mPoolObjects.Length; i++)
        {
            if (inGameObject.name == mPoolObjects[i]._Object.name)
            {
                mPoolObjects[i]._Object.SetActive(false);
                mPoolObjects[i]._Used = false;
            }
        }
    }
}
