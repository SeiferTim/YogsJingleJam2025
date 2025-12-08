package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class AboutSubState extends FlxSubState
{
	private var ready:Bool = false;
	private var bg:FlxSprite;
	private var border:FlxSprite;
	private var aboutText:FlxBitmapText;

	override public function create():Void
	{
		super.create();

		// Full black background (not transparent)
		bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0; // Start invisible for fade-in
		add(bg);

		// Border (like game over screen)
		border = new FlxSprite();
		border.makeGraphic(FlxG.width - 8, FlxG.height - 8, FlxColor.TRANSPARENT);
		border.drawRect(0, 0, border.width, border.height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.WHITE});
		border.x = 4;
		border.y = 4;
		border.alpha = 0; // Start invisible for fade-in
		add(border);

		// About text - centered on screen
		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");
		aboutText = new FlxBitmapText(font);
		aboutText.text = "Echoes of the Infinite Recursor\n\n" + "A game made by Tim I Hely\n" + "axolstudio.com\n\n"
			+ "For the 2025 Yogscast Jingle Game Jam\n" + "\"If you can't beat them, join them\"\n\n" + "With music and sfx by Laz the Composer\n"
			+ "lazthecomposer.itch.io\n\n" + "and assets by Oryx Design Lab\n" + "www.oryxdesignlab.com";
		aboutText.alignment = "center";
		aboutText.screenCenter();
		aboutText.alpha = 0; // Start invisible for fade-in
		add(aboutText);

		// Fade in everything
		FlxTween.tween(bg, {alpha: 1}, 0.2, {ease: FlxEase.sineIn});
		FlxTween.tween(border, {alpha: 1}, 0.2, {ease: FlxEase.sineIn});
		FlxTween.tween(aboutText, {alpha: 1}, 0.2, {
			ease: FlxEase.sineIn,
			onComplete: function(_)
			{
				ready = true;
			}
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready)
			return;

		// Close on any input
		var closePressed = false;

		#if !FLX_NO_KEYBOARD
		if (FlxG.keys.justPressed.ANY)
			closePressed = true;
		#end

		#if !FLX_NO_GAMEPAD
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && (gamepad.justPressed.B || gamepad.justPressed.BACK))
			closePressed = true;
		#end

		#if !FLX_NO_MOUSE
		if (FlxG.mouse.justPressed)
			closePressed = true;
		#end

		if (closePressed)
		{
			ready = false;
			// Fade out before closing
			FlxTween.tween(bg, {alpha: 0}, 0.2, {ease: FlxEase.sineOut});
			FlxTween.tween(border, {alpha: 0}, 0.2, {ease: FlxEase.sineOut});
			FlxTween.tween(aboutText, {alpha: 0}, 0.2, {
				ease: FlxEase.sineOut,
				onComplete: function(_)
				{
					close();
					// Re-enable menu after a frame
					if (_parentState != null && Reflect.hasField(_parentState, "ready"))
					{
						Reflect.setField(_parentState, "ready", true);
					}
				}
			});
		}
	}
}
