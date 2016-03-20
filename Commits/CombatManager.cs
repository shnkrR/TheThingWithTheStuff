using UnityEngine;
using System.Collections;

public class CombatManager 
{

	public float DealMeleeDamage(float _currEnemyHealth, float _weaponAccuracy, float _weaponDamage)
	{
		float a_newEnemyHealth=0;

		if(Random.Range(0,1f) > _weaponAccuracy)
		{
			a_newEnemyHealth = _currEnemyHealth - (_weaponDamage*_weaponAccuracy);
		}
		else 
		{
			a_newEnemyHealth = _currEnemyHealth - _weaponDamage;
		}
		
		return a_newEnemyHealth;
	}

	public float DealMeleeDamage(float _currEnemyHealth,float _weaponDamage)
	{
		float a_newEnemyHealth=0;
		a_newEnemyHealth = _currEnemyHealth - _weaponDamage;        
        
        return a_newEnemyHealth;
    }

	public float DealRangedDamage(float _currEnemyHealth, float _weaponAccuracy, float _weaponDamage)
	{
		float a_newEnemyHealth;
		if(Random.Range(0,1f) > _weaponAccuracy)
		{
			a_newEnemyHealth = _currEnemyHealth - (_weaponDamage*_weaponAccuracy);
		}
		else 
		{
			a_newEnemyHealth = _currEnemyHealth - _weaponDamage;
		}

		return a_newEnemyHealth;
	}

	public float DealRangedDamage(float _currEnemyHealth, float _weaponAccuracy, float _weaponDamage, float  _currVelocity, float _enemyVelocity)
	{
		float a_newEnemyHealth = 0;
		return a_newEnemyHealth;
	}
	public float DealRangedDamage(float _currEnemyHealth, float _weaponAccuracy, float _weaponDamage, float  _currVelocity, float _enemyVelocity, float _distance)
	{
		float a_newEnemyHealth = 0;
		return a_newEnemyHealth;
	}
}
