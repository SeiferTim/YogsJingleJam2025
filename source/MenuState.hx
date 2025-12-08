package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class MenuState extends FlxState
{
	private var nav:NavigableMenu;
	private var buttons:Array<GameButton> = [];
	private var ready:Bool = false;

	private var titleLogo:FlxSprite;
	private var newGameButton:GameButton;
	private var aboutButton:GameButton;
	private var clearSavesButton:GameButton;

	override public function create():Void
	{
		super.create();

		bgColor = FlxColor.BLACK;

		// Add title logo at top (same position as TitleState after slide-up)
		titleLogo = new FlxSprite();
		titleLogo.loadGraphic("assets/images/title.png");
		titleLogo.screenCenter(X);
		titleLogo.y = 2;
		add(titleLogo);

		// Create buttons below the logo (buttons are now 62x12 from graphic)
		var buttonWidth = 62;
		var startY = titleLogo.y + titleLogo.height + 5; // 20px gap below logo
		var spacing = 16;

		newGameButton = new GameButton((FlxG.width - buttonWidth) / 2, startY, "NEW GAME", onNewGame);
		newGameButton.alpha = 0; // Start invisible
		add(newGameButton);
		buttons.push(newGameButton);

		aboutButton = new GameButton((FlxG.width - buttonWidth) / 2, startY + spacing, "ABOUT", onAbout);
		aboutButton.alpha = 0; // Start invisible
		add(aboutButton);
		buttons.push(aboutButton);

		clearSavesButton = new GameButton((FlxG.width - buttonWidth) / 2, startY + spacing * 2, "CLEAR SAVES", onClearSaves);
		clearSavesButton.alpha = 0; // Start invisible
		add(clearSavesButton);
		buttons.push(clearSavesButton);

		// Create navigation helper
		nav = new NavigableMenu(cast buttons, GameGlobals.mouseHandler);
		nav.enabled = false; // Disable until fade in complete

		// Fade in from black, then fade in buttons

		// Fade in each button with a stagger
		for (i in 0...buttons.length)
		{
			FlxTween.tween(buttons[i], {alpha: 1}, 0.3, {
				ease: FlxEase.sineIn,
				startDelay: i * 0.1,
				onComplete: function(_)
				{
					if (i == buttons.length - 1)
					{
						ready = true;
						nav.enabled = true;
					}
				}
			});
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready)
			return;

		// Update navigation system
		nav.update(elapsed);
	}

	private function onNewGame():Void
	{
		if (!ready)
			return;

		ready = false;
		axollib.AxolAPI.sendEvent("NEW_GAME");
		FlxG.camera.fade(FlxColor.BLACK, 0.33, false, function()
		{
			FlxG.switchState(CharacterSelectState.new);
		});
	}

	private function onAbout():Void
	{
		if (!ready)
			return;

		ready = false;
		axollib.AxolAPI.sendEvent("VIEW_ABOUT");
		openSubState(new AboutSubState());
	}

	private function onClearSaves():Void
	{
		if (!ready)
			return;

		ready = false;
		openSubState(new ConfirmSubState("Clear all save data?", function(confirmed:Bool)
		{
			ready = true; // Re-enable after substate closes
			if (confirmed)
			{
				axollib.AxolAPI.sendEvent("CLEAR_SAVE_DATA");
				GameGlobals.clearAllData();
			}
		}));
	}
}
