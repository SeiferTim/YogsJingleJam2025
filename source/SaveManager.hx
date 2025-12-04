package;

import flixel.FlxG;
import flixel.util.FlxSave;

/**
 * Manages saving and loading ghost data between runs
 */
class SaveManager
{
	private static var _save:FlxSave;
	private static var _initialized:Bool = false;
	
	public static inline var SAVE_NAME:String = "YogsJingleJam2025";
	
	/**
	 * Initialize the save system
	 */
	public static function init():Void
	{
		if (_initialized)
			return;
		
		_save = new FlxSave();
		_save.bind(SAVE_NAME);
		
		// Initialize ghost array if it doesn't exist
		if (_save.data.ghosts == null)
		{
			_save.data.ghosts = [];
			_save.flush();
		}
		
		_initialized = true;
	}
	
	/**
	 * Save a character as a ghost (called on death)
	 */
	public static function saveGhost(character:CharacterData):Void
	{
		init();
		
		var ghosts:Array<Dynamic> = _save.data.ghosts;
		ghosts.push(character.toSaveData());
		
		_save.data.ghosts = ghosts;
		_save.flush();
		
		trace('Ghost saved: ${character.name} (Level ${character.level})');
	}
	
	/**
	 * Load all saved ghosts
	 */
	public static function loadGhosts():Array<CharacterData>
	{
		init();
		
		var ghosts:Array<CharacterData> = [];
		var savedGhosts:Array<Dynamic> = _save.data.ghosts;
		
		if (savedGhosts != null)
		{
			for (ghostData in savedGhosts)
			{
				ghosts.push(CharacterData.fromSaveData(ghostData));
			}
		}
		
		trace('Loaded ${ghosts.length} ghosts');
		return ghosts;
	}
	
	/**
	 * Get count of saved ghosts
	 */
	public static function getGhostCount():Int
	{
		init();
		
		var ghosts:Array<Dynamic> = _save.data.ghosts;
		return (ghosts != null) ? ghosts.length : 0;
	}
	
	/**
	 * Clear all saved ghosts (for reset option)
	 */
	public static function clearAllGhosts():Void
	{
		init();
		
		_save.data.ghosts = [];
		_save.flush();
		
		trace('All ghosts cleared');
	}
	
	/**
	 * Check if any ghosts exist
	 */
	public static function hasGhosts():Bool
	{
		return getGhostCount() > 0;
	}
	
	/**
	 * Save game settings (volume, etc) - for future use
	 */
	public static function saveSetting(key:String, value:Dynamic):Void
	{
		init();
		
		Reflect.setField(_save.data, key, value);
		_save.flush();
	}
	
	/**
	 * Load game setting
	 */
	public static function loadSetting(key:String, defaultValue:Dynamic = null):Dynamic
	{
		init();
		
		var value = Reflect.field(_save.data, key);
		return (value != null) ? value : defaultValue;
	}
}
