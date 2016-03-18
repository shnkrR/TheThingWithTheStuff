using UnityEngine;
using System.Collections;

public class Enums
{

	public enum PlayerState
	{
		None=0,
		Movement,
		Combat
	}

	public enum CombatState
	{
		None=0,
		Ranged,
		Melee
	}

	public enum MeleeAttackState
	{
		None=0,
		Attack1,
		Attack2,
		Attack3,
		Attack4
	}

	public enum Entity
	{
		None=0,
		Player,
		Enemy,
		Obstacle,
		Pickup
	}

//	public enum WeaponType
//	{
//		None =0,
//		Ranged,
//		Melee
//	}


}
