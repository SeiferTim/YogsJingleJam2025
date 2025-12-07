package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxButton.FlxTypedButton;
import flixel.util.FlxColor;

/**
 * Reusable button using the button-pick.png graphic with centered text label.
 * Usage: var button = new GameButton(x, y, width, height, "LABEL", onClickCallback);
 */
class GameButton extends FlxTypedButton<FlxBitmapText>
{
	public function new(X:Float, Y:Float, Width:Int, Height:Int, Label:String, OnClick:Void->Void)
	{
		super(X, Y, OnClick);

		// Load button graphic
		loadGraphic("assets/images/button-pick.png", true, Width, Height);

		// Create label with pixel font
		var font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);
		label = new FlxBitmapText(font);
		label.text = Label;
		label.color = FlxColor.WHITE;

		// Center label on button (offset is relative to button position)
		label.offset.x = -Math.floor((Width - label.width) / 2);
		label.offset.y = -Math.floor((Height - label.height) / 2);
	}
}
