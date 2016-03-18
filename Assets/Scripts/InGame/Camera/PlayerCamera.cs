using UnityEngine;
using System.Collections;

public class PlayerCamera : MonoBehaviour 
{
    public Vector3 _OffsetFromPlayer = new Vector3(1.35f, 0.65f, -5.0f);
    public Vector3 _Rotation = new Vector3(8.5f, 0.0f, 0.0f);

    public bool _SwitchShoulders = true;

    public float _SwitchSpeed = 0.25f;

    public PlayerController _Player;

    public GameObject _PlayerModel;

    private Transform mTransform;

    private bool mSwitchCamera = false;
    private float mSwitchValue;


	void Start () 
	{
        mTransform = transform;

        mTransform.localPosition = _OffsetFromPlayer;
        mTransform.localEulerAngles = _Rotation;

        mSwitchCamera = false;
        mSwitchValue = _OffsetFromPlayer.x;
	}

    void Update()
    {
        float dist = Vector3.Distance(_Player.transform.position, _Player._AI.position);
        if (dist > _Player.p_meleeDistance)
        {
            mTransform.position = _PlayerModel.transform.position;

            mTransform.LookAt(_Player._AI.position);

            mTransform.position += mTransform.forward * _OffsetFromPlayer.z;
            mTransform.position += new Vector3(_OffsetFromPlayer.x, _OffsetFromPlayer.y, 0.0f);

            mTransform.localEulerAngles += _Rotation;
        }
        else
        {
            Vector3 midPoint = (_Player.transform.position + _Player._AI.position) / 2.0f;

            mTransform.localEulerAngles = new Vector3(mTransform.localEulerAngles.x, 0.0f, 0.0f);
            mTransform.position = midPoint;
            mTransform.position -= mTransform.right * dist;            
            mTransform.LookAt(midPoint);
        }
    }
}
