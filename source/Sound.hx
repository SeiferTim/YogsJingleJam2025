package;

import flixel.FlxG;
import flixel.sound.FlxSound;

class Sound
{
	private static var soundsInitialized:Bool = false;
	private static var soundLibrary:Map<String, String>;
	private static var musicLibrary:Map<String, MusicData>;
	private static var currentMusicTrackName:String = null;
	private static var eggCrackStep:Int = 0; // Track which egg crack sound to play next (0-2)

	public static function initSounds():Void
	{
		if (soundsInitialized)
			return;
		soundsInitialized = true;

		FlxG.sound.cacheAll();

		musicLibrary = new Map<String, MusicData>();

		musicLibrary.set("menu", new MusicData("menu", "assets/music/music_title_theme_loop.ogg", 44000, true));
		musicLibrary.set("ghosts", new MusicData("ghosts", "assets/music/music_ghosts_loop.ogg", 46545, true));
		musicLibrary.set("phase1", new MusicData("phase1", "assets/music/music_phase_I_loop.ogg", 46545, true));
		musicLibrary.set("phase2", new MusicData("phase2", "assets/music/music_phase_II_loop.ogg", 36000, true));
		musicLibrary.set("phase3", new MusicData("phase3", "assets/music/music_phase_III_loop.ogg", 41142, true));
		musicLibrary.set("victory", new MusicData("victory", "assets/music/music_victory.ogg", 0, false)); // Non-looping

		// Initialize sound effects library
		soundLibrary = new Map<String, String>();
		soundLibrary.set("arrow_shoot", "assets/sounds/arrow_shoot.ogg");
		soundLibrary.set("arrow_hit_1", "assets/sounds/arrow_hit_1.ogg");
		soundLibrary.set("arrow_hit_2", "assets/sounds/arrow_hit_2.ogg");
		soundLibrary.set("boss_roar", "assets/sounds/boss_roar.ogg");
		soundLibrary.set("bubble_pop", "assets/sounds/bubble_pop.ogg");
		soundLibrary.set("egg_crack_1", "assets/sounds/egg_crack_1.ogg");
		soundLibrary.set("egg_crack_2", "assets/sounds/egg_crack_2.ogg");
		soundLibrary.set("egg_crack_emerge", "assets/sounds/egg_crack_emerge.ogg");
		soundLibrary.set("fire_bubble", "assets/sounds/fire_bubble.ogg");
		soundLibrary.set("ghost_appears", "assets/sounds/ghost appears.ogg");
		soundLibrary.set("ghost_defeat", "assets/sounds/ghost_defeat.ogg");
		soundLibrary.set("magic_bubble_loop", "assets/sounds/magic_bubble_loop.ogg");
		soundLibrary.set("monster_hit", "assets/sounds/monster_hit.ogg");
		soundLibrary.set("player_dodge_1", "assets/sounds/player_dodge_1.ogg");
		soundLibrary.set("player_dodge_2", "assets/sounds/player_dodge_2.ogg");
		soundLibrary.set("player_dodge_3", "assets/sounds/player_dodge_3.ogg");
		soundLibrary.set("player_heal", "assets/sounds/player_heal.ogg");
		soundLibrary.set("player_hurt_1", "assets/sounds/player_hurt_1.ogg");
		soundLibrary.set("player_hurt_2", "assets/sounds/player_hurt_2.ogg");
		soundLibrary.set("player_hurt_3", "assets/sounds/player_hurt_3.ogg");
		soundLibrary.set("slam_impact", "assets/sounds/slam_impact.ogg");
		soundLibrary.set("sparks", "assets/sounds/sparks.ogg");
		soundLibrary.set("sword_hit_1", "assets/sounds/sword_hit_1.ogg");
		soundLibrary.set("sword_hit_2", "assets/sounds/sword_hit_2.ogg");
		soundLibrary.set("sword_hit_3", "assets/sounds/sword_hit_3.ogg");
		soundLibrary.set("sword_spin", "assets/sounds/sword_spin.ogg");
		soundLibrary.set("sword_sweep_1", "assets/sounds/sword_sweep_1.ogg");
		soundLibrary.set("sword_sweep_2", "assets/sounds/sword_sweep_2.ogg");
	}

	public static function playMusic(trackName:String):Void
	{
		if (!soundsInitialized)
			initSounds();

		if (currentMusicTrackName == trackName)
			return;
		if (currentMusicTrackName != null)
		{
			var currentMusic:MusicData = musicLibrary.get(currentMusicTrackName);
			FlxG.sound.music.stop();
		}

		var music:MusicData = musicLibrary.get(trackName);
		if (music != null)
		{
			// Load music using FlxSound directly for better control
			var sound = FlxG.sound.load(music.path, 1.0, music.loops); // Use music.loops setting
			if (music.loops)
			{
				sound.loopTime = music.loopTime;
			}
			sound.persist = true; // Keep music playing between state changes
			sound.play();
			FlxG.sound.music = sound;
			currentMusicTrackName = trackName;

			#if html5
			trace("Playing music: " + trackName + " (using Web Audio API: " + sound.playing + ")");
			#end
		}
	}

	public static function stopMusic(Force:Bool = false):Void
	{
		if (currentMusicTrackName != null && FlxG.sound.music != null)
		{
			if (Force)
				FlxG.sound.music.stop();
			else
				FlxG.sound.music.fadeOut(0.5);

			currentMusicTrackName = null;
		}
	}

	/**
	 * Play a sound effect by name
	 */
	public static function playSound(soundName:String, volume:Float = 1.0, loop:Bool = false, ?onComplete:Void->Void):FlxSound
	{
		if (!soundsInitialized)
			initSounds();

		var path = soundLibrary.get(soundName);
		if (path != null)
		{
			return FlxG.sound.play(path, volume, loop, null, false, onComplete);
		}
		else
		{
			trace("Sound not found: " + soundName);
		}
		return null;
	}

	/**
	 * Play a random variant of a sound (e.g., "player_hurt" picks from player_hurt_1/2/3)
	 */
	public static function playSoundRandom(baseName:String, variants:Int = 3, volume:Float = 1.0):Void
	{
		var choice = FlxG.random.int(1, variants);
		playSound(baseName + "_" + choice, volume);
	}

	/**
	 * Play egg crack sounds in sequence (1, 2, emerge)
	 */
	public static function playEggCrack():Void
	{
		if (eggCrackStep == 0)
		{
			playSound("egg_crack_1");
			eggCrackStep = 1;
		}
		else if (eggCrackStep == 1)
		{
			playSound("egg_crack_2");
			eggCrackStep = 2;
		}
		else
		{
			playSound("egg_crack_emerge");
			eggCrackStep = 0; // Reset for next time
		}
	}
}

class MusicData
{
	public var name:String;
	public var path:String;
	public var loopTime:Int;
	public var loops:Bool;

	public function new(name:String, path:String, loopTime:Int, loops:Bool = true)
	{
		this.name = name;
		this.path = path;
		this.loopTime = loopTime;
		this.loops = loops;
	}
}
