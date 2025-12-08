package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxButton.FlxTypedButton;
import flixel.util.FlxColor;

/**
 * Reusable button using the button-pick.png graphic with centered text label.
 * Usage: var button = new GameButton(x, y, "LABEL", onClickCallback);
 */
class GameButton extends FlxTypedButton<FlxBitmapText>
{
	public function new(X:Float, Y:Float, Label:String, OnClick:Void->Void)
	{
		super(X, Y, OnClick);

		// Load button-pick.png (3 frames: normal, hover, pressed - each 62x12)
		loadGraphic(AssetPaths.button_pick__png, true, 62, 12);

		// Create label with pixel font
		var font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);
		label = new FlxBitmapText(font);
		label.text = Label;
		label.color = FlxColor.WHITE;

		// Calculate center position for label
		labelOffsets[0].x = labelOffsets[1].x = labelOffsets[2].x = Math.floor((62 - label.width) / 2);
		labelOffsets[0].y = labelOffsets[1].y = labelOffsets[2].y = Math.floor((12 - label.height) / 2);
	}
}
