package;

import flixel.FlxG;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;

class Actions
{
	public static var actions:FlxActionManager;
	public static var gameplayIndex:Int = -1;

	public static var up:FlxActionDigital;
	public static var down:FlxActionDigital;
	public static var left:FlxActionDigital;
	public static var right:FlxActionDigital;
	public static var shoot:FlxActionDigital;
	public static var dodge:FlxActionDigital;

	public static var leftStick:FlxActionAnalog;
	public static var rightStick:FlxActionAnalog;

	private static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;

		Actions.actions = FlxG.inputs.addUniqueType(new FlxActionManager());
		Actions.actions.resetOnStateSwitch = NONE;

		Actions.up = new FlxActionDigital();
		Actions.down = new FlxActionDigital();
		Actions.left = new FlxActionDigital();
		Actions.right = new FlxActionDigital();
		Actions.shoot = new FlxActionDigital();
		Actions.dodge = new FlxActionDigital();

		Actions.leftStick = new FlxActionAnalog();
		Actions.rightStick = new FlxActionAnalog();

		var gameplaySet = new FlxActionSet("Gameplay", [
			Actions.up,
			Actions.down,
			Actions.left,
			Actions.right,
			Actions.shoot,
			Actions.dodge
		], [Actions.leftStick, Actions.rightStick]);

		gameplayIndex = Actions.actions.addSet(gameplaySet);

		Actions.up.addKey(UP, PRESSED);
		Actions.up.addKey(W, PRESSED);
		Actions.down.addKey(DOWN, PRESSED);
		Actions.down.addKey(S, PRESSED);
		Actions.left.addKey(LEFT, PRESSED);
		Actions.left.addKey(A, PRESSED);
		Actions.right.addKey(RIGHT, PRESSED);
		Actions.right.addKey(D, PRESSED);

		Actions.shoot.addKey(SPACE, PRESSED);
		Actions.shoot.addMouse(LEFT, PRESSED);
		Actions.shoot.addGamepad(A, PRESSED);
		Actions.shoot.addGamepad(RIGHT_TRIGGER, PRESSED);

		Actions.dodge.addKey(SHIFT, JUST_PRESSED);
		Actions.dodge.addGamepad(B, JUST_PRESSED);

		Actions.up.addGamepad(DPAD_UP, PRESSED);
		Actions.down.addGamepad(DPAD_DOWN, PRESSED);
		Actions.left.addGamepad(DPAD_LEFT, PRESSED);
		Actions.right.addGamepad(DPAD_RIGHT, PRESSED);

		Actions.up.addGamepad(LEFT_STICK_DIGITAL_UP, PRESSED);
		Actions.down.addGamepad(LEFT_STICK_DIGITAL_DOWN, PRESSED);
		Actions.left.addGamepad(LEFT_STICK_DIGITAL_LEFT, PRESSED);
		Actions.right.addGamepad(LEFT_STICK_DIGITAL_RIGHT, PRESSED);

		Actions.leftStick.addGamepad(LEFT_ANALOG_STICK, MOVED);
		Actions.rightStick.addGamepad(RIGHT_ANALOG_STICK, MOVED);

		Actions.actions.activateSet(gameplayIndex, FlxInputDevice.ALL, FlxInputDeviceID.FIRST_ACTIVE);
	}
}
