package;

import flixel.FlxSprite;

/**
 * Simple shadow sprite that follows its parent.
 * Uses predefined shadow graphics or parent's graphic.
 */
class Shadow extends FlxSprite
{
	public var parent:FlxSprite;
	public var anchorOffsetX:Float = 0;
	public var anchorOffsetY:Float = 0;
	public var groundY:Null<Float> = null; // Optional: Override Y position to ground level

	/**
	 * Create a shadow that follows a parent sprite
	 * @param Parent The sprite to create shadow from
	 * @param Type Shadow type: "player", "bug", or "bossSegment"
	 * @param AnchorOffsetX X offset from parent center (default 0)
	 * @param AnchorOffsetY Y offset from parent center (default based on type)
	 */
	public function new(Parent:FlxSprite, Type:String, ?AnchorOffsetX:Float = 0, ?AnchorOffsetY:Float = null)
	{
		super();
		parent = Parent;
		anchorOffsetX = AnchorOffsetX;

		// Set default anchor offset based on type
		if (AnchorOffsetY != null)
		{
			anchorOffsetY = AnchorOffsetY;
		}
		else
		{
			anchorOffsetY = switch (Type.toLowerCase())
			{
				case "player": 4;
				case "bug": 12;
				case "bosssegment": 4;
				default: 0;
			}
		}

		// Load appropriate graphic based on type
		switch (Type.toLowerCase())
		{
			case "player":
				loadGraphic("assets/images/player-shadow.png");
				antialiasing = false;
				
			case "bug":
				loadGraphic("assets/images/bug-shadow.png");
				antialiasing = false;
				
			case "bosssegment":
				// Use parent's graphic (copy the shape)
				createBossSegmentShadow();
				
			default:
				// Fallback: simple black rectangle
				makeGraphic(Std.int(parent.width), Std.int(parent.height), 0xFF000000);
		}

		updatePosition();
	}

	function createBossSegmentShadow():Void
	{
		// Create shadow from parent's alpha channel
		var sourceGraphic = parent.graphic;
		if (sourceGraphic == null)
		{
			// Fallback
			makeGraphic(Std.int(parent.width), Std.int(parent.height), 0xFF000000);
			return;
		}

		var shadowWidth = Std.int(parent.frameWidth);
		var shadowHeight = Std.int(parent.frameHeight);

		makeGraphic(shadowWidth, shadowHeight, 0x00000000, true); // Transparent background

		var sourcePixels = sourceGraphic.bitmap;
		var shadowPixels = graphic.bitmap;

		// Copy shape from parent's alpha channel
		for (sy in 0...shadowHeight)
		{
			for (sx in 0...shadowWidth)
			{
				if (sx < parent.frameWidth && sy < parent.frameHeight)
				{
					var sourceAlpha = sourcePixels.getPixel32(sx, sy) >> 24 & 0xFF;
					if (sourceAlpha > 0)
					{
						shadowPixels.setPixel32(sx, sy, 0xFF000000); // Solid black
					}
				}
			}
		}
	}

	public function updatePosition():Void
	{
		if (parent == null)
		{
			kill();
			return;
		}
		if (!parent.exists)
		{
			exists = false;
			return;
		}

		// Calculate parent's center
		var parentCenterX = parent.x + parent.width / 2;
		var parentCenterY = parent.y + parent.height / 2;

		// Position shadow center at anchor point
		x = parentCenterX + anchorOffsetX - width / 2;
		// Use groundY override if set, otherwise follow parent
		if (groundY != null)
			y = groundY + anchorOffsetY - height / 2;
		else
			y = parentCenterY + anchorOffsetY - height / 2;

		// Match parent's visibility and alpha
		visible = parent.visible;
		alpha = parent.alpha;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		updatePosition();
	}

	override function destroy():Void
	{
		parent = null;
		super.destroy();
	}
}