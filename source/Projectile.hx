package;

import flixel.FlxSprite;

class Projectile extends FlxSprite
{
	public var damage:Float = 1.0;
	public var isStuck:Bool = false;
	public var sticksToWalls:Bool = true; // New: control sticking behavior
	public var sticksToEnemies:Bool = false; // New: control enemy sticking

	var stickTime:Float = 5;
	var stickTimer:Float = 0;
	var lastX:Float = 0;
	var lastY:Float = 0;

	public function new()
	{
		super();
	}

	override function update(elapsed:Float):Void
	{
		if (!isStuck)
		{
			lastX = x;
			lastY = y;
			super.update(elapsed);
		}
		else
		{
			super.update(elapsed);
		}

		if (isStuck)
		{
			stickTimer += elapsed;
			if (stickTimer >= stickTime)
			{
				kill();
			}
		}
	}

	public function stick():Void
	{
		isStuck = true;
		stickTimer = 0;
		alive = false;
		velocity.set(0, 0);
		acceleration.set(0, 0);
	}

	override function revive():Void
	{
		super.revive();
		isStuck = false;
		stickTimer = 0;
		lastX = x;
		lastY = y;
		sticksToWalls = true;
		sticksToEnemies = false;
	}
}
