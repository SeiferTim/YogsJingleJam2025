package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

/**
 * Custom button using FlxBitmapFont for pixel-perfect text rendering
 */
class PixelButton extends FlxSpriteGroup
{
	public var background:FlxSprite;
	public var label:FlxBitmapText;
	public var onClick:Void->Void;

	var isPressed:Bool = false;
	var isHovered:Bool = false;

	public function new(X:Float, Y:Float, Width:Int, Height:Int, Text:String, Font:FlxBitmapFont, OnClick:Void->Void)
	{
		super(X, Y);

		this.onClick = OnClick;

		// Background
		background = new FlxSprite(0, 0);
		background.makeGraphic(Width, Height, 0xff16a085); // Dark green/teal
		add(background);

		// Label - centered
		label = new FlxBitmapText(Font);
		label.text = Text;
		// label.letterSpacing = 1;
		label.x = Math.floor((Width - label.width) / 2);
		label.y = Math.floor((Height - label.height) / 2);
		label.color = FlxColor.WHITE;
		add(label);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if FLX_MOUSE
		var mouseOver = background.overlapsPoint(flixel.FlxG.mouse.getPosition());

		if (mouseOver)
		{
			if (!isHovered)
			{
				isHovered = true;
				background.color = 0xff1abc9c; // Lighter green on hover
			}

			if (flixel.FlxG.mouse.justPressed)
			{
				isPressed = true;
				background.color = 0xff138d75; // Darker green on press
			}

			if (flixel.FlxG.mouse.justReleased && isPressed)
			{
				isPressed = false;
				if (onClick != null)
					onClick();
			}
		}
		else
		{
			if (isHovered)
			{
				isHovered = false;
				background.color = 0xff16a085; // Reset to default
			}
			isPressed = false;
		}
		#end
	}
}
