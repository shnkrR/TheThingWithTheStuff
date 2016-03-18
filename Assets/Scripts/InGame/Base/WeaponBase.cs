using UnityEngine;
using System.Collections;

public class WeaponBase : MonoBehaviour {

    //BASE MELEE STATS

    public float m_meleeAttackRate;
    public float m_meleeDamage;


    //BASE RANGED STATS
    public float m_clipCapacity;
    public float m_refireRate;
    public float m_rangedDamage;

    public GameObject m_MeleeWeapon;
    public GameObject m_RangeWeapon;
}
