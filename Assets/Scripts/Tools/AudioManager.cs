using UnityEngine;
using System.Collections;

public class AudioManager : MonoBehaviour 
{
	public AudioClip	_MenuIntroMusic;
	public AudioClip	_InGameIntroMusic;
	public AudioClip	_GameWonIntroMusic;
	public AudioClip	_GameLostIntroMusic;

	public AudioClip[] 	_MovesSFX;

	public AudioSource	_SfxSource;
	public AudioSource	_MusicSource;

	public void Awake()
	{
		PlayMenuIntroMusic();

        //GameManager._GameStartEvent += PlayGameIntroMusic;
        //GameManager._GameWonEvent += PlayGameWonIntroMusic;
        //GameManager._GameLostEvent += PlayGameLostIntroMusic;
        //GameManager._GameRestartEvent += PlayGameIntroMusic;
        //GameManager._GameUpdateMoveEvent += PlayMovesSfx;
	}

	public void OnDestroy()
	{
        //GameManager._GameStartEvent -= PlayGameIntroMusic;
        //GameManager._GameWonEvent -= PlayGameWonIntroMusic;
        //GameManager._GameLostEvent -= PlayGameLostIntroMusic;
        //GameManager._GameRestartEvent -= PlayGameIntroMusic;
        //GameManager._GameUpdateMoveEvent -= PlayMovesSfx;
	}

	private void PlayMovesSfx(int moves)
	{
		int randIndex = Random.Range(0, _MovesSFX.Length);
		PlaySFX(_MovesSFX[randIndex]);
	}

	private void PlayMenuIntroMusic()
	{
		PlayMusic(_MenuIntroMusic);
	}

	private void PlayGameIntroMusic()
	{
		PlayMusic(_InGameIntroMusic);
	}

	private void PlayGameWonIntroMusic()
	{
		PlayMusic(_GameWonIntroMusic);
	}

	private void PlayGameLostIntroMusic()
	{
		PlayMusic(_GameLostIntroMusic);
	}

	private void PlaySFX(AudioClip clip)
	{
		if(clip == null)
			return;

		_SfxSource.Stop();
		_SfxSource.PlayOneShot(clip);
	}

	private void PlayMusic(AudioClip clip)
	{
		if(clip == null)
			return;

		_MusicSource.Stop ();
		_MusicSource.PlayOneShot(clip);
	}
}
