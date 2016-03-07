using UnityEngine;
using System.Collections;

public static class CameraBounds 
{
	private static Camera mCamera;
    public static Camera pCamera { get { return mCamera; } }

	private static Vector4 mBounds;
	public static Vector4 pBounds {	get	{ return mBounds; } }

	private static float mWidth;
	public static float pWidth { get { return mWidth; } }

	private static float mHeight;
	public static float pHeight { get { return mHeight; } }


	public static void SetCamera(Camera inCamera)
	{
		if (inCamera != null)
			mCamera = inCamera;

		CalculateBounds ();
	}

	private static void CalculateBounds()
	{
		if (mCamera != null)
		{
			Vector3 botLeft = mCamera.ViewportToWorldPoint(Vector3.zero);
			Vector3 topRight= mCamera.ViewportToWorldPoint(Vector3.one);
			mBounds = new Vector4(botLeft.x, topRight.x, topRight.y, botLeft.y);
			mWidth = Mathf.Abs(CameraBounds.pBounds.y) + Mathf.Abs(CameraBounds.pBounds.x);
			mHeight = Mathf.Abs(CameraBounds.pBounds.z) + Mathf.Abs(CameraBounds.pBounds.w);
		}
	}
}
