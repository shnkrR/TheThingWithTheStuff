using UnityEngine;
using System.Collections;

public class ObFitToCamera : MonoBase 
{
	public Vector3 _ScaleOffset;

	private void Start()
	{
		Vector3 scale = gameObject.transform.localScale;
		scale.x = CameraBounds.pWidth;
		scale.y = CameraBounds.pHeight;

		scale += _ScaleOffset;

		gameObject.transform.localScale = scale;
	}
}
