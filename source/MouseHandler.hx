package;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.display.PixelSnapping;
import openfl.events.Event;

class MouseHandler extends FlxSprite
{
	public var cursor(get, set):MouseCursor;

	private var currentCursor:MouseCursor;

	public var loaded:Bool = false;
	public var mScale:Float = 1.0;

	public function new():Void
	{
		super();

		// Load the cursor graphic (now with 7 frames including reticle at frame 6)
		loadGraphic("assets/images/cursors.png", true, 32, 32); // 2x larger graphics now
		animation.add("finger", [0], 0, false);
		animation.add("finger-down", [1], 0, false);
		animation.add("reticle", [6], 0, false); // Frame 6 is the reticle
		pixelPerfectPosition = pixelPerfectRender = true;
		antialiasing = false;

		// Make this sprite invisible - we only use it to render the cursor bitmap
		visible = false;
		active = true;

		currentCursor = MouseCursor.FINGER;
		cursor = MouseCursor.FINGER;

		// Set up mouse events
		FlxG.stage.addEventListener(Event.RESIZE, (e) ->
		{
			loadMouse();
		});

		FlxG.stage.addEventListener(Event.FULLSCREEN, (e) ->
		{
			loadMouse();
		});

		loadMouse();
	}

	public function loadMouse():Void
	{
		loaded = true;

		// Simple approach - scale 1, no offsets (graphics are now 2x larger)
		FlxG.mouse.load(null, 1, 0, 0);
		FlxG.mouse.cursor.smoothing = false;
		FlxG.mouse.cursor.pixelSnapping = PixelSnapping.ALWAYS;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!FlxG.mouse.visible || !loaded)
		{
			return;
		}

		// Handle click animation
		if (cursor == MouseCursor.FINGER && FlxG.mouse.justPressed)
		{
			cursor = MouseCursor.FINGER_DOWN;
		}
		else if (cursor == MouseCursor.FINGER_DOWN && FlxG.mouse.justReleased)
		{
			cursor = MouseCursor.FINGER;
		}

		// Update the cursor graphic
		drawFrame();
		if (framePixels != null)
		{
			FlxG.mouse.cursor.bitmapData = framePixels.clone();
		}
	}

	private function set_cursor(Value:MouseCursor):MouseCursor
	{
		switch (Value)
		{
			case FINGER:
				animation.play("finger");
			case FINGER_DOWN:
				animation.play("finger-down");
			case RETICLE:
				animation.play("reticle");
		}
		return currentCursor = Value;
	}

	private function get_cursor():MouseCursor
	{
		return currentCursor;
	}
}

enum abstract MouseCursor(String) from String to String
{
	var FINGER = "finger";
	var FINGER_DOWN = "finger-down";
	var RETICLE = "reticle";
}
