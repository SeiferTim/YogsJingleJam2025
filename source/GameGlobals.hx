package;

import axollib.AxolAPI;
import flixel.FlxG;
import flixel.util.FlxSave;

class GameGlobals
{
	private static var _initialized:Bool = false;

	public static var gameSave:FlxSave;
	public static var playerID:String = "";
	public static var mouseHandler:MouseHandler;

	public static function init():Void
	{
		if (_initialized)
			return;
		_initialized = true;

		FlxG.autoPause = false;

		// Initialize custom mouse handler and add it as a plugin so it updates
		mouseHandler = new MouseHandler();
		FlxG.plugins.addPlugin(mouseHandler);
		FlxG.mouse.visible = true;

		// Initialize save system
		initSave();

		// Initialize AxolAPI with game key and player ID
		AxolAPI.initSave(playerID, gameSave);
		AxolAPI.initialize("6d2854d1b7a34873999b97898f557230", playerID);
		Sound.initSounds();
		// Send game start event
		AxolAPI.sendEvent("GAME_START");
	}

	public static function initSave():Void
	{
		gameSave = new FlxSave();
		gameSave.bind("YogsJingleJam2025Save");

		if (gameSave.data.playerID != null)
		{
			playerID = gameSave.data.playerID;
		}
		else
		{
			playerID = AxolAPI.generateGUID();
			gameSave.data.playerID = playerID;
			gameSave.flush();
		}
	}

	public static function clearAllData():Void
	{
		if (gameSave != null)
		{
			gameSave.erase();
		}
		// Reinitialize with fresh data
		initSave();
	}
}
