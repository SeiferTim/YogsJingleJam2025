package;

import axollib.AxolAPI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.utils.Object;

using StringTools;

class VictorySubState extends FlxSubState
{
	private var ready:Bool = false;
	private var overlay:FlxSprite;
	private var victoryText:FlxBitmapText;
	private var initialsText:FlxBitmapText;
	private var currentInitials:String = "";
	private var maxLength:Int = 3;
	private var deathCount:Int = 0;
	private var characterName:String = "";
	private var submitting:Bool = false;
	private var submitted:Bool = false;

	public function new(deaths:Int, charName:String)
	{
		super();
		this.deathCount = deaths;
		this.characterName = charName;
	}

	override public function create():Void
	{
		super.create();

		// Play victory music
		Sound.playMusic("victory");

		// Dark overlay
		overlay = new FlxSprite();
		overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = 0.8;
		add(overlay);

		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");

		// VICTORY text
		victoryText = new FlxBitmapText(font);
		victoryText.text = "VICTORY!";
		victoryText.alignment = "center";
		victoryText.screenCenter(X);
		victoryText.y = 20;
		victoryText.scale.set(2, 2);
		add(victoryText);

		// Stats
		var statsText = new FlxBitmapText(font);
		statsText.text = "CHARACTER: " + characterName + "\nDEATHS: " + deathCount;
		statsText.alignment = "center";
		statsText.screenCenter(X);
		statsText.y = 55;
		add(statsText);

		// Initials prompt
		var promptText = new FlxBitmapText(font);
		promptText.text = "ENTER YOUR INITIALS:";
		promptText.alignment = "center";
		promptText.screenCenter(X);
		promptText.y = 85;
		add(promptText);

		// Initials display
		initialsText = new FlxBitmapText(font);
		initialsText.text = "___";
		initialsText.alignment = "center";
		initialsText.screenCenter(X);
		initialsText.y = 100;
		initialsText.scale.set(2, 2);
		add(initialsText);

		// Instructions
		var instructions = new FlxBitmapText(font);
		instructions.text = "TYPE INITIALS\nPRESS ENTER TO SUBMIT";
		instructions.alignment = "center";
		instructions.screenCenter(X);
		instructions.y = FlxG.height - 30;
		instructions.scale.set(0.7, 0.7);
		add(instructions);

		FlxG.camera.fade(FlxColor.BLACK, 0.3, true, function()
		{
			ready = true;
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready || submitting || submitted)
			return;

		#if !FLX_NO_KEYBOARD
		// Handle text input
		if (FlxG.keys.justPressed.ANY)
		{
			if (currentInitials.length < maxLength)
			{
				// Get pressed key as letter
				var key = FlxG.keys.getIsDown();
				for (k in key)
				{
					var letter = Std.string(k);
					if (letter.length == 1)
					{
						var charCode = letter.toUpperCase().charCodeAt(0);
						if (charCode >= 65 && charCode <= 90) // A-Z
						{
							currentInitials += letter.toUpperCase();
							updateInitialsDisplay();
							break;
						}
					}
				}
			}
		}

		// Backspace to delete
		if (FlxG.keys.justPressed.BACKSPACE && currentInitials.length > 0)
		{
			currentInitials = currentInitials.substr(0, currentInitials.length - 1);
			updateInitialsDisplay();
		}

		// Submit on Enter
		if (FlxG.keys.justPressed.ENTER && currentInitials.length == maxLength)
		{
			submitScore();
		}
		#end
	}

	private function updateInitialsDisplay():Void
	{
		var display = currentInitials;
		while (display.length < maxLength)
		{
			display += "_";
		}
		initialsText.text = display;
		initialsText.screenCenter(X);
	}

	private function submitScore():Void
	{
		if (submitting || submitted)
			return;

		submitting = true;
		ready = false;

		// Submit to AxolAPI - sendScore(amount, initials, callback)
		// Score is death count (lower is better)
		AxolAPI.sendScore(deathCount, currentInitials, onSubmitResponse);
	}

	private function onSubmitResponse(data:String):Void
	{
		submitted = true;
		submitting = false;

		if (data == null)
		{
			onSubmitError("No response from server");
			return;
		}

		try
		{
			var response:Object = Json.parse(data);
			if (response.status == 200)
			{
				onSubmitSuccess(response);
			}
			else
			{
				onSubmitError("Server error: " + response.status_message);
			}
		}
		catch (e:Dynamic)
		{
			onSubmitError("Parse error: " + Std.string(e));
		}
	}

	private function onSubmitSuccess(response:Object):Void
	{
		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");

		// Show success message
		var successText = new FlxBitmapText(font);
		successText.text = "SCORE SUBMITTED!";
		successText.alignment = "center";
		successText.screenCenter();
		add(successText);

		// Wait then go to high scores
		haxe.Timer.delay(function()
		{
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
			{
				FlxG.switchState(HighScoresState.new);
			});
		}, 2000);
	}

	private function onSubmitError(error:String):Void
	{
		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");

		// Show error message
		var errorText = new FlxBitmapText(font);
		errorText.text = "ERROR SUBMITTING\n" + error + "\nPRESS ANY KEY";
		errorText.alignment = "center";
		errorText.screenCenter();
		add(errorText);

		ready = true; // Allow closing
	}
}
