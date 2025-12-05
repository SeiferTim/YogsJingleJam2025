package;

import flixel.FlxG;

/**
 * Static class to track game state across scenes
 * Uses FlxSave to persist dead characters across game sessions
 */
class GameData
{
	private static var _save:flixel.util.FlxSave;
	private static var _initialized:Bool = false;

	// Initialize FlxSave
	private static function init():Void
	{
		if (_initialized)
			return;

		_save = new flixel.util.FlxSave();
		_save.bind("YogsJingleJam2025");

		#if debug
		// In debug mode, start with a clean slate every time
		_save.data.deadCharacters = [];
		_save.flush();
		trace("GameData initialized with FlxSave (DEBUG MODE - save cleared)");
		#else
		trace("GameData initialized with FlxSave");
		#end

		_initialized = true;
	}

	// Add a dead character to persistent storage
	public static function addDeadCharacter(character:CharacterData):Void
	{
		init();

		var deadList:Array<Dynamic> = _save.data.deadCharacters;
		if (deadList == null)
			deadList = [];

		// Add this character to the list (allow duplicates for accumulation)
		deadList.push(character.toSaveData());

		_save.data.deadCharacters = deadList;
		_save.flush();

		trace("Added dead character: " + character.name + " (Total ghosts: " + deadList.length + ")");
	}

	// Get all dead characters for ghost spawning
	public static function getDeadCharacters():Array<CharacterData>
	{
		init();

		var deadList:Array<Dynamic> = _save.data.deadCharacters;
		if (deadList == null)
			return [];

		var result:Array<CharacterData> = [];
		for (data in deadList)
		{
			result.push(CharacterData.fromSaveData(data));
		}

		return result;
	}

	// Clear all dead characters (for manual save wipe)
	public static function reset():Void
	{
		init();

		_save.data.deadCharacters = [];
		_save.flush();

		trace("GameData reset - cleared all ghosts from save");
	}

	// Get count of ghosts without loading them all
	public static function getGhostCount():Int
	{
		init();

		var deadList:Array<Dynamic> = _save.data.deadCharacters;
		return deadList != null ? deadList.length : 0;
	}
}
