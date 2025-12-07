package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class DeathScreenSubState extends FlxSubState
{
	var characterName:String;
	var deathPhase:Int;
	var panel:FlxSprite;
	var ready:Bool = true;

	public function new(CharacterName:String, DeathPhase:Int)
	{
		super();
		characterName = CharacterName;
		deathPhase = DeathPhase;
	}

	override function create():Void
	{
		super.create();

		// Transparent background (no fade needed)
		bgColor = FlxColor.TRANSPARENT;

		// Semi-transparent dark overlay for better readability
		var overlay = new FlxSprite();
		overlay.makeGraphic(FlxG.width, FlxG.height, 0x80000000); // 50% transparent black
		overlay.scrollFactor.set(0, 0);
		add(overlay);

		// Panel dimensions
		var panelWidth = 200;
		var panelHeight = 100;
		var panelX = Math.floor((FlxG.width - panelWidth) / 2);
		var panelY = Math.floor((FlxG.height - panelHeight) / 2);

		// Panel background with border
		panel = new FlxSprite(panelX, panelY);
		panel.makeGraphic(panelWidth, panelHeight, 0xFF000000); // Black background
		panel.scrollFactor.set(0, 0);
		add(panel);

		// Panel border (lighter)
		var border = new FlxSprite(panelX, panelY);
		border.makeGraphic(panelWidth, panelHeight, FlxColor.TRANSPARENT);
		// Draw border manually (top, right, bottom, left)
		border.drawRect(0, 0, panelWidth, 1, 0xFF444444);
		border.drawRect(0, 0, 1, panelHeight, 0xFF444444);
		border.drawRect(0, panelHeight - 1, panelWidth, 1, 0xFF444444);
		border.drawRect(panelWidth - 1, 0, 1, panelHeight, 0xFF444444);
		border.scrollFactor.set(0, 0);
		add(border);

		// Load pixel font
		var font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);

		// "DEFEATED" title - large and centered
		var defeatedText = new FlxBitmapText(font);
		defeatedText.text = "DEFEATED";
		defeatedText.scrollFactor.set(0, 0);
		defeatedText.x = Math.floor((FlxG.width - defeatedText.width) / 2);
		defeatedText.y = panelY + 8;
		add(defeatedText);

		// Ominous message about soul being claimed - properly centered
		var soulText = new FlxBitmapText(font);
		soulText.text = "The soul of " + characterName;
		soulText.scrollFactor.set(0, 0);
		soulText.x = Math.floor((FlxG.width - soulText.width) / 2);
		soulText.y = panelY + 24;
		add(soulText);

		var soulText2 = new FlxBitmapText(font);
		soulText2.text = "has been claimed by the";
		soulText2.scrollFactor.set(0, 0);
		soulText2.x = Math.floor((FlxG.width - soulText2.width) / 2);
		soulText2.y = panelY + 32;
		add(soulText2);

		var soulText3 = new FlxBitmapText(font);
		soulText3.text = "Infinite Recursor";
		soulText3.scrollFactor.set(0, 0);
		soulText3.x = Math.floor((FlxG.width - soulText3.width) / 2);
		soulText3.y = panelY + 40;
		add(soulText3);

		// Buttons at bottom of panel
		var buttonY = panelY + panelHeight - 20;
		var buttonSpacing = 10;
		var buttonWidth = 62; // Match button-pick.png dimensions
		var buttonHeight = 12;

		// Calculate positions to center both buttons with spacing
		var totalButtonWidth = (buttonWidth * 2) + buttonSpacing;
		var startX = Math.floor((FlxG.width - totalButtonWidth) / 2);

		// "New Challenger" button
		var newChallengerBtn = new GameButton(startX, buttonY, buttonWidth, buttonHeight, "NEXT", function()
		{
			if (!ready)
				return;
			ready = false;
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
			{
				FlxG.switchState(() -> new CharacterSelectState());
			});
		});
		newChallengerBtn.scrollFactor.set(0, 0);
		add(newChallengerBtn);

		// "Exit" button
		var exitBtn = new GameButton(startX + buttonWidth + buttonSpacing, buttonY, buttonWidth, buttonHeight, "EXIT", function()
		{
			if (!ready)
				return;
			ready = false;
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
			{
				// TODO: Go to main menu
				close();
			});
		});
		exitBtn.scrollFactor.set(0, 0);
		add(exitBtn);

		// Start everything invisible and fade in slowly
		for (basic in members)
		{
			if (basic != null && (basic is FlxSprite))
			{
				cast(basic, FlxSprite).alpha = 0;
			}
		}

		// Fade everything in over 1.5 seconds
		FlxTween.num(0, 1, 1.5, {}, function(value:Float)
		{
			for (basic in members)
			{
				if (basic != null && (basic is FlxSprite))
				{
					cast(basic, FlxSprite).alpha = value;
				}
			}
		});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready)
			return;

		// Allow keyboard shortcuts
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
		{
			// Go to character select (New Challenger)
			ready = false;
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
			{
				FlxG.switchState(() -> new CharacterSelectState());
			});
		}
		else if (FlxG.keys.justPressed.ESCAPE)
		{
			// Exit
			ready = false;
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
			{
				close();
			});
		}
	}
}
