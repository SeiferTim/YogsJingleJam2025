package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.util.FlxSignal;

/**
 * Helper class for keyboard/gamepad menu navigation.
 * Automatically moves mouse cursor to buttons and handles input.
 */
class NavigableMenu
{
	public var buttons:Array<FlxButton>;
	public var selectedIndex:Int = 0;
	public var enabled:Bool = true;

	private var mouseHandler:MouseHandler;
	private var lastInputTime:Float = 0;
	private var inputDelay:Float = 0.15; // Prevent rapid-fire input

	public function new(Buttons:Array<FlxButton>, ?MouseHandler:MouseHandler)
	{
		buttons = Buttons;
		mouseHandler = MouseHandler;

		if (buttons.length > 0)
		{
			updateMousePosition();
		}
	}

	public function update(elapsed:Float):Void
	{
		if (!enabled || buttons.length == 0)
			return;

		lastInputTime += elapsed;

		// Check for navigation input
		var prevIndex = selectedIndex;

		// Keyboard navigation
		#if !FLX_NO_KEYBOARD
		if (lastInputTime >= inputDelay)
		{
			if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
			{
				selectedIndex--;
				lastInputTime = 0;
			}
			else if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
			{
				selectedIndex++;
				lastInputTime = 0;
			}
			else if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
			{
				selectedIndex--;
				lastInputTime = 0;
			}
			else if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
			{
				selectedIndex++;
				lastInputTime = 0;
			}
		}
		#end

		// Gamepad navigation
		#if !FLX_NO_GAMEPAD
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && lastInputTime >= inputDelay)
		{
			var leftStickY = gamepad.analog.value.LEFT_STICK_Y;
			var leftStickX = gamepad.analog.value.LEFT_STICK_X;

			if (gamepad.justPressed.DPAD_UP || (leftStickY < -0.5 && Math.abs(leftStickY) > Math.abs(leftStickX)))
			{
				selectedIndex--;
				lastInputTime = 0;
			}
			else if (gamepad.justPressed.DPAD_DOWN || (leftStickY > 0.5 && Math.abs(leftStickY) > Math.abs(leftStickX)))
			{
				selectedIndex++;
				lastInputTime = 0;
			}
			else if (gamepad.justPressed.DPAD_LEFT || (leftStickX < -0.5 && Math.abs(leftStickX) > Math.abs(leftStickY)))
			{
				selectedIndex--;
				lastInputTime = 0;
			}
			else if (gamepad.justPressed.DPAD_RIGHT || (leftStickX > 0.5 && Math.abs(leftStickX) > Math.abs(leftStickY)))
			{
				selectedIndex++;
				lastInputTime = 0;
			}
		}
		#end

		// Wrap around
		if (selectedIndex < 0)
			selectedIndex = buttons.length - 1;
		if (selectedIndex >= buttons.length)
			selectedIndex = 0;

		// Update mouse position if selection changed
		if (prevIndex != selectedIndex)
		{
			updateMousePosition();
		}

		// Check for activation input
		var shouldActivate = false;

		#if !FLX_NO_KEYBOARD
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z)
			shouldActivate = true;
		#end

		#if !FLX_NO_GAMEPAD
		if (gamepad != null && (gamepad.justPressed.A || gamepad.justPressed.START))
			shouldActivate = true;
		#end

		if (shouldActivate && buttons[selectedIndex] != null)
		{
			// Simulate button press
			if (mouseHandler != null)
				mouseHandler.cursor = FINGER_DOWN;

			buttons[selectedIndex].onUp.fire();

			// Reset mouse cursor after a frame
			if (mouseHandler != null)
			{
				new flixel.util.FlxTimer().start(0.1, function(_)
				{
					mouseHandler.cursor = FINGER;
				});
			}
		}
	}

	public function updateMousePosition():Void
	{
		if (buttons[selectedIndex] == null)
			return;

		var button = buttons[selectedIndex];

		// Position mouse at bottom-right of button (finger pointing at it)
		var targetX = button.x + button.width - 8;
		var targetY = button.y + button.height - 8;

		// Set mouse position (this is in world coordinates)
		FlxG.mouse.setRawPositionUnsafe(targetX, targetY);
	}

	public function setSelectedIndex(index:Int):Void
	{
		selectedIndex = index;
		if (selectedIndex < 0)
			selectedIndex = 0;
		if (selectedIndex >= buttons.length)
			selectedIndex = buttons.length - 1;
		updateMousePosition();
	}
}
