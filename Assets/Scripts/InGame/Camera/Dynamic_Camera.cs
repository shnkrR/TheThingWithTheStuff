using UnityEngine;
using System.Collections;

public class Dynamic_Camera : MonoBehaviour
{
	public Transform aiPlayer;
	public Transform playerTransform;
	public GameObject world;
	public float height	;
	public float distance;
	Transform myTransform;
	Vector3 lookPos;
	Vector3 direction;
	public float lookDistance ;
	
	public Transform johnface;
	
	float forword ;
	public static bool _gearshift;
	float intencity=0.005f;
	public float maxintencity;
	float elapsedTime;
	
	float initialfov;

	Vector3 lookpos1;
	float initialintencity;
    bool foveffect;
	void Start () 
	{
		myTransform =transform;
			
		johnface = GameObject.Find("john face").transform;
					
		initialfov = Camera.main.fieldOfView;
	}
			
	void LateUpdate () 
	{
        update();
	}
	
	void update()
	{
		
			distance = Mathf.Lerp(distance,6,Time.deltaTime);
			height = Mathf.Lerp(height,1,Time.deltaTime);
		
		direction = playerTransform.position - aiPlayer.position;
		lookDistance = Mathf.Abs(playerTransform.position.z - aiPlayer.position.z);
		direction.Normalize();
		
		if( lookDistance > distance)
			lookDistance = distance;
		
				elapsedTime+=Time.deltaTime;
	    
		myTransform.position = playerTransform.position + playerTransform.right * distance;
		Vector3 tempPos = playerTransform.position + direction * lookDistance;
		Vector3 targetPos = tempPos + distance * Vector3.right;
		targetPos.y = height ;//+0.05f*Mathf.Cos(elapsedTime);
		
		
			
        //         switch(JohnPlayer.johnPlayer._gameState)
        //        {
        //        case JohnPlayer.GAMESTATES.IDLE:			forword = 3.0f;break;
        //        case JohnPlayer.GAMESTATES.PRELAUNCH:		forword = 3.0f;break;
        //        case JohnPlayer.GAMESTATES.ONGAME:	        forword = Mathf.Lerp(forword,1,Time.deltaTime*JohnPlayer._BikeSpeed*0.5f);
        //                                                     myTransform.localPosition+=Random.insideUnitSphere*Time.deltaTime;
        //                                                                    break;	
        //        }
			
        //        targetPos.z = targetPos.z*Vector3.forward.z*forword;
		
        //    float rate = 1.0f;
		
        //        myTransform.position = Vector3.Lerp(myTransform.position,targetPos,rate);
		
        //lookPos = playerTransform.position;// - lookDistance * direction;
        // lookpos1 = lookPos;
			
        //         switch(_gearshift)
        //        {
        //        case true:			Camera.main.fov = Mathf.Lerp(Camera.main.fov,45,Time.deltaTime*10);
        //                           if(Camera.main.fov>=44f) _gearshift = false;
        //                           if(JohnPlayer._Gear<6) 			intencity = 1.5f;
        //                                     break;
        //        case false:         Camera.main.fov = Mathf.Lerp(Camera.main.fov,35,Time.deltaTime*10);
        //                                    break;
        //        }
				
        //lookpos1 = lookPos;//+Random.insideUnitSphere*Time.deltaTime*intencity;
        //myTransform.LookAt(lookpos1);
		
        //if(intencity>0.01f)
        //intencity-=Time.deltaTime;
			 
		
	}
	
	
	
}
