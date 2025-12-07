package;

import flixel.FlxSprite;

class Projectile extends FlxSprite
{
	public var damage:Float = 1.0;
	public var isStuck:Bool = false;
	public var sticksToWalls:Bool = true;

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

	public function hitWall():Void
	{
		// Default behavior: stick to wall if sticksToWalls is true, otherwise die
		if (sticksToWalls)
		{
			stick();
		}
		else
		{
			kill();
		}
	}

	public function hitEnemy():Void
	{
		// Default behavior: just kill the projectile
		kill();
	}

	override function revive():Void
	{
		super.revive();
		isStuck = false;
		stickTimer = 0;
		lastX = x;
		lastY = y;
		sticksToWalls = false;
	}
}
