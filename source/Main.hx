package;

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

		addChild(new FlxGame(256, 144, CharacterSelectState, 60, 60, true));
	}
}
