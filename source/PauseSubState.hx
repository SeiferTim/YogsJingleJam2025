package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class PauseSubState extends FlxSubState
{
	private var ready:Bool = false;
	private var nav:NavigableMenu;
	private var overlay:FlxSprite;
	private var panel:FlxSprite;
	private var buttons:Array<GameButton> = [];

	private var resumeButton:GameButton;
	private var restartButton:GameButton;
	private var quitButton:GameButton;

	override public function create():Void
	{
		super.create();

		axollib.AxolAPI.sendEvent("GAME_PAUSED");

		// Set cursor to FINGER for menus
		if (GameGlobals.mouseHandler != null)
			GameGlobals.mouseHandler.cursor = FINGER;

		// Dark overlay
		overlay = new FlxSprite();
		overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = 0.5;
		add(overlay);

		// Pause panel - smaller, centered box
		var panelWidth = 80;
		var panelHeight = 60;
		panel = new FlxSprite();
		panel.makeGraphic(panelWidth, panelHeight, FlxColor.BLACK);
		panel.screenCenter();
		add(panel);

		// Add border
		var border = new FlxSprite();
		border.makeGraphic(panelWidth, panelHeight, FlxColor.TRANSPARENT);
		border.x = panel.x;
		border.y = panel.y;
		border.drawRect(0, 0, panelWidth, panelHeight, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.WHITE});
		add(border);

		// PAUSED text
		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");
		var pausedText = new FlxBitmapText(font);
		pausedText.text = "PAUSED";
		pausedText.alignment = "center";
		pausedText.screenCenter(X);
		pausedText.y = panel.y + 4;
		add(pausedText);

		// Buttons (62x12) - centered in panel
		var startY = panel.y + 18;
		var spacing = 14;

		resumeButton = new GameButton((FlxG.width - 62) / 2, startY, "RESUME", onResume);
		add(resumeButton);
		buttons.push(resumeButton);

		restartButton = new GameButton((FlxG.width - 62) / 2, startY + spacing, "RESTART", onRestart);
		add(restartButton);
		buttons.push(restartButton);

		quitButton = new GameButton((FlxG.width - 62) / 2, startY + spacing * 2, "QUIT", onQuit);
		add(quitButton);
		buttons.push(quitButton);

		// Create navigation
		nav = new NavigableMenu(cast buttons, GameGlobals.mouseHandler);
		nav.enabled = false;

		// Small delay before ready
		haxe.Timer.delay(function()
		{
			ready = true;
			nav.enabled = true;
		}, 200);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready)
			return;

		// Quick resume with pause key
		#if !FLX_NO_KEYBOARD
		if (FlxG.keys.justPressed.P || FlxG.keys.justPressed.ESCAPE)
		{
			onResume();
			return;
		}
		#end

		#if !FLX_NO_GAMEPAD
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && gamepad.justPressed.START)
		{
			onResume();
			return;
		}
		#end

		// Update navigation
		nav.update(elapsed);
	}

	private function onResume():Void
	{
		// Restore RETICLE cursor for gameplay
		if (GameGlobals.mouseHandler != null)
			GameGlobals.mouseHandler.cursor = RETICLE;
		close();
	}

	private function onRestart():Void
	{
		close();
		FlxG.resetState();
	}

	private function onQuit():Void
	{
		// Set to FINGER for menu
		if (GameGlobals.mouseHandler != null)
			GameGlobals.mouseHandler.cursor = FINGER;
		close();
		FlxG.switchState(TitleState.new);
	}
}
