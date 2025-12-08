package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class TitleState extends FlxState
{
	private var titleLogo:FlxSprite;
	private var pressStartText:FlxBitmapText;
	private var copyrightText:FlxBitmapText;
	private var blinkTimer:Float = 0;
	private var showPressStart:Bool = true;
	private var canStart:Bool = false;
	private var pressStartVisible:Bool = false;
	private var ready:Bool = false;
	private var copy:FlxSprite;

	override public function create():Void
	{
		super.create();

		bgColor = FlxColor.BLACK;

		// Start menu music
		Sound.playMusic("menu");

		// Load and center title logo
		titleLogo = new FlxSprite();
		titleLogo.loadGraphic("assets/images/title.png");
		titleLogo.screenCenter();
		titleLogo.y -= 20; // Move up 10 pixels
		titleLogo.alpha = 0; // Start invisible
		add(titleLogo);

		// Create copyright text (bottom right)
		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");
		copyrightText = new FlxBitmapText(font);
		copyrightText.text = "2025 Axol Studio, LLC";
		copyrightText.alignment = "right";
		copyrightText.x = FlxG.width - copyrightText.width - 4;
		copyrightText.y = FlxG.height - copyrightText.height - 4;
		copyrightText.alpha = 0; // Start invisible
		add(copyrightText);

		copy = new FlxSprite("assets/images/copyright.png");
		copy.x = copyrightText.x - 9;
		copy.y = copyrightText.y;
		copy.alpha = 0; // Start invisible
		add(copy);

		// Create "Press Start" text (moved up 10 pixels)
		pressStartText = new FlxBitmapText(font);
		pressStartText.text = "PRESS START";
		pressStartText.alignment = "right";

		pressStartText.y = copyrightText.y - pressStartText.height - 20; // Changed from -4 to -14
		pressStartText.alpha = 0; // Start invisible
		add(pressStartText);

		// Cinematic sequence: fade in black -> logo -> wait -> copyright/press start
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true, function()
		{
			// Fade in logo
			FlxTween.tween(titleLogo, {alpha: 1}, 1.0, {
				ease: FlxEase.sineIn,
				onComplete: function(_)
				{
					// Wait a moment, then fade in copyright and press start
					new FlxTimer().start(0.5, function(_)
					{
						pressStartText.screenCenter(X);
						FlxTween.tween(copyrightText, {alpha: 1}, 0.5, {ease: FlxEase.sineIn});
						FlxTween.tween(copy, {alpha: 1}, 0.5, {ease: FlxEase.sineIn});
						FlxTween.tween(pressStartText, {alpha: 1}, 0.5, {
							ease: FlxEase.sineIn,
							onComplete: function(_)
							{
								pressStartVisible = true;
								canStart = true;
								ready = true;
							}
						});
					});
				}
			});
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready)
			return;

		// Blink "Press Start" text
		if (pressStartVisible)
		{
			blinkTimer += elapsed;
			if (blinkTimer >= 0.5)
			{
				blinkTimer = 0;
				showPressStart = !showPressStart;
				pressStartText.visible = showPressStart;
			}
		}

		// Check for any input to start
		if (canStart)
		{
			var startPressed = false;

			#if !FLX_NO_KEYBOARD
			if (FlxG.keys.justPressed.ANY)
				startPressed = true;
			#end

			#if !FLX_NO_GAMEPAD
			var gamepad = FlxG.gamepads.lastActive;
			if (gamepad != null && gamepad.justPressed.ANY)
				startPressed = true;
			#end

			#if !FLX_NO_MOUSE
			if (FlxG.mouse.justPressed)
				startPressed = true;
			#end

			if (startPressed)
			{
				canStart = false;
				ready = false;

				// Slide logo up to near the top
				var targetY = 2;
				FlxTween.tween(titleLogo, {y: targetY}, 0.5, {
					ease: FlxEase.quadOut,
					onComplete: function(_)
					{
						FlxG.switchState(MenuState.new);
					}
				});
			}
		}
	}
}
