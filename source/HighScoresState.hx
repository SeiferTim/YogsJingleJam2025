package;

import axollib.AxolAPI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.utils.Object;

class HighScoresState extends FlxState
{
	private var ready:Bool = false;
	private var scores:Array<Object> = [];
	private var scoreTexts:Array<FlxBitmapText> = [];
	private var loading:Bool = true;
	private var loadingText:FlxBitmapText;

	override public function create():Void
	{
		super.create();

		bgColor = FlxColor.BLACK;

		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");

		// Title
		var title = new FlxBitmapText(font);
		title.text = "HIGH SCORES";
		title.alignment = "center";
		title.screenCenter(X);
		title.y = 10;
		add(title);

		// Loading text
		loadingText = new FlxBitmapText(font);
		loadingText.text = "LOADING...";
		loadingText.screenCenter();
		add(loadingText);

		// Instructions
		var instructions = new FlxBitmapText(font);
		instructions.text = "PRESS ANY KEY TO RETURN";
		instructions.alignment = "center";
		instructions.screenCenter(X);
		instructions.y = FlxG.height - 20;
		add(instructions);

		// Fetch scores from AxolAPI
		AxolAPI.getScores(onScoresReceived);

		FlxG.camera.fade(FlxColor.BLACK, 0.3, true);
	}

	private function onScoresReceived(data:String):Void
	{
		loading = false;
		loadingText.visible = false;

		if (data == null)
		{
			onScoresError("No data received");
			return;
		}

		try
		{
			var response:Object = Json.parse(data);
			if (response.status == 200 && response.data != null && response.data.scores != null)
			{
				scores = response.data.scores;
				displayScores();
			}
			else
			{
				onScoresError("Invalid response");
			}
		}
		catch (e:Dynamic)
		{
			onScoresError("Parse error: " + Std.string(e));
		}
	}

	private function displayScores():Void
	{
		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");

		// Display scores
		var startY = 30;
		var lineHeight = 12;

		for (i in 0...Std.int(Math.min(scores.length, 10)))
		{
			var scoreEntry:Object = scores[i];
			var text = new FlxBitmapText(font);

			// Format: "1. ABC - 5 deaths"
			var position = scoreEntry.position != null ? Std.string(scoreEntry.position) : Std.string(i + 1);
			var initials = scoreEntry.initials != null ? scoreEntry.initials : "???";
			var amount = scoreEntry.amount != null ? Std.string(scoreEntry.amount) : "0";

			text.text = position + ". " + initials + " - " + amount + " DEATHS";
			text.x = 10;
			text.y = startY + (i * lineHeight);
			add(text);
			scoreTexts.push(text);
		}

		if (scores.length == 0)
		{
			var noScores = new FlxBitmapText(font);
			noScores.text = "NO SCORES YET";
			noScores.screenCenter();
			add(noScores);
		}

		ready = true;
	}

	private function onScoresError(error:String):Void
	{
		loading = false;
		loadingText.text = "ERROR LOADING SCORES\n" + error;
		loadingText.screenCenter();
		ready = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready)
			return;

		// Return to menu on any input
		var backPressed = false;

		#if !FLX_NO_KEYBOARD
		if (FlxG.keys.justPressed.ANY)
			backPressed = true;
		#end

		#if !FLX_NO_GAMEPAD
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && gamepad.justPressed.ANY)
			backPressed = true;
		#end

		#if !FLX_NO_MOUSE
		if (FlxG.mouse.justPressed)
			backPressed = true;
		#end

		if (backPressed)
		{
			ready = false;
			FlxG.camera.fade(FlxColor.BLACK, 0.3, false, function()
			{
				FlxG.switchState(MenuState.new);
			});
		}
	}
}
