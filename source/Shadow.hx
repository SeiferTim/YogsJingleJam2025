package;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class Shadow extends FlxSprite
{
	public var parent:FlxSprite;
	public var offsetX:Float = 0;
	public var offsetY:Float = 2;

	public function new(Parent:FlxSprite, ?OffsetX:Float = 0, ?OffsetY:Float = 1)
	{
		super();
		parent = Parent;
		offsetX = OffsetX;
		offsetY = OffsetY;

		// Create an oval shadow
		var shadowWidth = Std.int(parent.width * 0.8); // Slightly narrower than parent
		var shadowHeight = Std.int(parent.height * 0.8); // Much flatter (oval)

		makeGraphic(shadowWidth, shadowHeight, FlxColor.TRANSPARENT, true);

		// Draw an oval/ellipse - full opacity, we'll control transparency via rendering
		FlxSpriteUtil.drawEllipse(this, 0, 0, shadowWidth, shadowHeight, FlxColor.BLACK);

		// Match parent's scale if any
		scale.copyFrom(parent.scale);

		updatePosition();
	}

	public function updatePosition():Void
	{
		if (parent == null || !parent.exists)
		{
			kill();
			return;
		}

		// Follow parent with offset - center the shadow under the parent
		x = parent.x + (parent.width - width) / 2 + offsetX;
		y = parent.y + parent.height - height + offsetY;

		// Match parent's visibility - shadows are full opacity when drawn to bitmap
		visible = parent.visible && parent.alpha > 0;
		alpha = 1.0;
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
