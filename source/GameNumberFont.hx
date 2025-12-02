package;

import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;

class GameNumberFont
{
	static var font:FlxBitmapFont;

	public static function loadFont():FlxBitmapFont
	{
		if (font == null)
		{
			font = FlxBitmapFont.fromAngelCode("assets/images/sml-digits.png", "assets/images/sml-digits.xml");
		}
		return font;
	}

	public static function createText(X:Float, Y:Float, text:String):FlxBitmapText
	{
		loadFont();
		var bitmapText = new FlxBitmapText(font);
		bitmapText.text = text;
		bitmapText.x = X;
		bitmapText.y = Y;
		bitmapText.scrollFactor.set(0, 0);
		return bitmapText;
	}
}
