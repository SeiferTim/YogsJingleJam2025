package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

class ConfirmSubState extends FlxSubState
{
	private var ready:Bool = false;
	private var nav:NavigableMenu;
	private var overlay:FlxSprite;
	private var promptText:FlxBitmapText;
	private var yesButton:GameButton;
	private var noButton:GameButton;
	private var callback:Bool->Void;
	private var buttons:Array<GameButton> = [];

	public function new(prompt:String, onComplete:Bool->Void)
	{
		super();
		this.callback = onComplete;

		// Store prompt for use in create
		_cachedPrompt = prompt;
	}

	private var _cachedPrompt:String;

	override public function create():Void
	{
		super.create();

		// Dark overlay
		overlay = new FlxSprite();
		overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = 0.8;
		add(overlay);

		// Dialog box background
		var dialogWidth = 200;
		var dialogHeight = 80;
		var dialog = new FlxSprite();
		dialog.makeGraphic(dialogWidth, dialogHeight, FlxColor.GRAY);
		dialog.screenCenter();
		add(dialog);

		// Border
		var border = new FlxSprite();
		border.makeGraphic(dialogWidth + 4, dialogHeight + 4, FlxColor.WHITE);
		border.screenCenter();
		border.x -= 2;
		border.y -= 2;
		insert(members.indexOf(dialog), border);

		// Prompt text
		var font = FlxBitmapFont.fromAngelCode("assets/images/sml-font.png", "assets/images/sml-font.xml");
		promptText = new FlxBitmapText(font);
		promptText.text = _cachedPrompt;
		promptText.alignment = "center";
		promptText.fieldWidth = dialogWidth - 10;
		promptText.screenCenter();
		promptText.y = dialog.y + 10;
		add(promptText);

		// Buttons
		var buttonWidth = 60;
		var buttonHeight = 12;
		var buttonY = dialog.y + dialogHeight - buttonHeight - 10;

		yesButton = new GameButton(dialog.x + 20, buttonY, "YES", onYes);
		add(yesButton);
		buttons.push(yesButton);

		noButton = new GameButton(dialog.x + dialogWidth - 62 - 20, buttonY, "NO", onNo);
		add(noButton);
		buttons.push(noButton);

		// Create navigation (start with NO selected)
		nav = new NavigableMenu(cast buttons, GameGlobals.mouseHandler);
		nav.setSelectedIndex(1); // Default to NO
		nav.enabled = false;

		// Fade in
		FlxG.camera.fade(FlxColor.BLACK, 0.2, true, function()
		{
			ready = true;
			nav.enabled = true;
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!ready)
			return;

		// ESC/B to cancel
		#if !FLX_NO_KEYBOARD
		if (FlxG.keys.justPressed.ESCAPE)
		{
			onNo();
			return;
		}
		#end

		#if !FLX_NO_GAMEPAD
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && gamepad.justPressed.B)
		{
			onNo();
			return;
		}
		#end

		// Update navigation
		nav.update(elapsed);
	}

	private function onYes():Void
	{
		if (callback != null)
			callback(true);
		close();
	}

	private function onNo():Void
	{
		if (callback != null)
			callback(false);
		close();
	}
}
