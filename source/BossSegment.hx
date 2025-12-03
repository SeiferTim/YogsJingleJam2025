package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

class BossSegment
{
	public var sprite:FlxSprite;
	public var parent:BossSegment;
	public var baseOffsetY:Float = 0;

	public function new(Sprite:FlxSprite, BaseOffsetY:Float, ?Parent:BossSegment)
	{
		sprite = Sprite;
		baseOffsetY = BaseOffsetY;
		parent = Parent;
	}

	public function getCenter():FlxPoint
	{
		return FlxPoint.get(sprite.x + sprite.width / 2, sprite.y + sprite.height / 2);
	}

	public function setCenter(x:Float, y:Float):Void
	{
		sprite.x = x - sprite.width / 2;
		sprite.y = y - sprite.height / 2;
	}

	public function destroy():Void
	{
		sprite = null;
		parent = null;
	}
}
