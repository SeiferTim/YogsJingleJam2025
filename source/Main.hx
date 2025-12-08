package;

import axollib.AxolAPI;
import axollib.SpookyAxolversaryState;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		// Disable antialiasing for pixel-perfect rendering
		FlxSprite.defaultAntialiasing = false;

		// Initialize name database (compile-time embedded data)
		NameData.init();

		// Set up AxolAPI configuration
		AxolAPI.firstState = TitleState;
		AxolAPI.init = GameGlobals.init;

		// Start with modified splash screen
		addChild(new FlxGame(256, 144, SpookyAxolversaryState, 60, 60, true));
	}
}
