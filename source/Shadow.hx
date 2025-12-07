package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;

class Shadow extends FlxSprite
{
	public var parent:FlxSprite;
	public var anchorOffsetX:Float = 0;
	public var anchorOffsetY:Float = 0;
	public var widthMultiplier:Float = 1.0;
	public var heightMultiplier:Float = 1.0;

	/**
	 * Create a shadow from a parent sprite
	 * @param Parent The sprite to create shadow from
	 * @param WidthMult Width multiplier (default 1.0)
	 * @param HeightMult Height multiplier (default 1.0)
	 * @param AnchorOffsetX X offset from parent center (default 0)
	 * @param AnchorOffsetY Y offset from parent center (default 0)
	 * @param UseAlpha If true, use parent's alpha channel instead of circle (default false)
	 */
	public function new(Parent:FlxSprite, ?WidthMult:Float = 1.0, ?HeightMult:Float = 1.0, ?AnchorOffsetX:Float = 0, ?AnchorOffsetY:Float = 0,
			?UseAlpha:Bool = false)
	{
		super();
		parent = Parent;
		widthMultiplier = WidthMult;
		heightMultiplier = HeightMult;
		anchorOffsetX = AnchorOffsetX;
		anchorOffsetY = AnchorOffsetY;

		var shadowWidth = Std.int(parent.width * widthMultiplier);
		var shadowHeight = Std.int(parent.height * heightMultiplier);

		// Force dimensions to be even
		if (shadowWidth % 2 == 1)
			shadowWidth++;
		if (shadowHeight % 2 == 1)
			shadowHeight++;

		if (UseAlpha || true)
		{
			// Use parent's alpha channel to create shadow
			createAlphaShadow(shadowWidth, shadowHeight);
		}
		else
		{
			// Draw simple black circle/ellipse
			makeGraphic(shadowWidth, shadowHeight, FlxColor.TRANSPARENT, true);
			
			var g = FlxGraphic.fromRectangle(shadowWidth, shadowHeight, FlxColor.TRANSPARENT, true);
			var pixels = g.bitmap;

			// Draw filled ellipse
			var centerX = shadowWidth / 2;
			var centerY = shadowHeight / 2;
			var radiusX = shadowWidth / 2;
			var radiusY = shadowHeight / 2;

			for (py in 0...shadowHeight)
			{
				for (px in 0...shadowWidth)
				{
					var dx = (px - centerX) / radiusX;
					var dy = (py - centerY) / radiusY;
					if (dx * dx + dy * dy <= 1.0)
					{
						pixels.setPixel32(px, py, FlxColor.BLACK);
					}
				}
			}
			
			loadGraphic(g);
		}

		updatePosition();
	}

	function createAlphaShadow(shadowWidth:Int, shadowHeight:Int):Void
	{
		// Create shadow from parent's alpha channel
		var sourceGraphic = parent.graphic;
		if (sourceGraphic == null)
		{
			// Fallback to circle
			makeGraphic(shadowWidth, shadowHeight, FlxColor.BLACK);
			return;
		}

		makeGraphic(shadowWidth, shadowHeight, FlxColor.TRANSPARENT, true);

		var sourcePixels = sourceGraphic.bitmap;
		var shadowPixels = graphic.bitmap;

		var scaleX = parent.frameWidth / shadowWidth;
		var scaleY = parent.frameHeight / shadowHeight;

		for (sy in 0...shadowHeight)
		{
			for (sx in 0...shadowWidth)
			{
				var sourceX = Std.int(sx * scaleX);
				var sourceY = Std.int(sy * scaleY);

				if (sourceX >= 0 && sourceX < parent.frameWidth && sourceY >= 0 && sourceY < parent.frameHeight)
				{
					var sourceAlpha = sourcePixels.getPixel32(sourceX, sourceY) >> 24 & 0xFF;
					if (sourceAlpha > 0)
					{
						shadowPixels.setPixel32(sx, sy, FlxColor.BLACK);
					}
				}
			}
		}
	}

	public function updatePosition():Void
	{
		if (parent == null || !parent.exists)
		{
			kill();
			return;
		}

		// Calculate parent's center (ignoring offset!)
		var parentCenterX = parent.x + parent.width / 2;
		var parentCenterY = parent.y + parent.height / 2;

		// Position shadow center at anchor point
		x = parentCenterX + anchorOffsetX - width / 2;
		y = parentCenterY + anchorOffsetY - height / 2;

		// Match parent's visibility
		visible = parent.visible && parent.alpha > 0;
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
