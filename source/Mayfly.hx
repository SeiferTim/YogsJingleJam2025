package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;

class Mayfly extends FlxSprite
{
	public var shadow:Shadow;
	public var currentHealth:Float = 1;

	var moveSpeed:Float = 30;
	var target:FlxPoint;
	var mp:FlxPoint;
	var changeDirectionTimer:Float = 0;
	var isEnteringArena:Bool = false;

	public function new()
	{
		super();

		currentHealth = 1;
		target = FlxPoint.get(-1, -1);
		mp = FlxPoint.get();
		loadGraphic(AssetPaths.mayfly__png, true, 8, 8);
		animation.add("fly", [0, 1], 6, true);
		animation.play("fly");
		kill();
	}

	public function spawn():Void
	{
		currentHealth = 1;
		var side = FlxG.random.int(0, 2);
		var spawnX:Float = 0;
		var spawnY:Float = 0;

		switch (side)
		{
			case 0:
				spawnX = FlxG.random.float(-28, PlayState.current.map.width + 20);
				spawnY = FlxG.worldBounds.top - 20;
			case 1:
				spawnX = FlxG.worldBounds.right + 20;
				spawnY = FlxG.random.float(-28, PlayState.current.map.height * 0.4);
			case 2:
				spawnX = FlxG.worldBounds.left - 28;
				spawnY = FlxG.random.float(-28, PlayState.current.map.height * 0.4);
		}
		pickNewTarget();
		isEnteringArena = true;
		changeDirectionTimer = 10.0;

		reset(spawnX, spawnY);

		if (shadow == null)
		{
			shadow = new Shadow(this, 0.5, 0.5, 0, height);
			PlayState.current.shadowLayer.add(shadow);
		}
		else
		{
			shadow.revive();
		}
	}

	function pickNewTarget():Void
	{
		if (isEnteringArena)
			return;

		var arenaHeight = FlxG.worldBounds.height;
		var upperArea = FlxG.worldBounds.top + (arenaHeight * 0.4);
		target.set(FlxG.random.float(FlxG.worldBounds.left + 40, FlxG.worldBounds.right - 40), FlxG.random.float(FlxG.worldBounds.top + 40, upperArea - 20));

		changeDirectionTimer = FlxG.random.float(0.5, 3.0);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		updateMovement(elapsed);
	}

	public function updateMovement(elapsed:Float):Void
	{
		changeDirectionTimer -= elapsed;
		if (changeDirectionTimer <= 0)
		{
			pickNewTarget();
		}
		getMidpoint(mp);
		if (mp.distanceTo(target) <= 4)
		{
			velocity.set();
		}
		else
		{
			FlxVelocity.moveTowardsPoint(this, target, moveSpeed);
		}
		if (!isEnteringArena)
		{
			x = FlxMath.bound(x, FlxG.worldBounds.left, FlxG.worldBounds.right - width);
			y = FlxMath.bound(y, FlxG.worldBounds.top, FlxG.worldBounds.bottom - height);
		}
	}

	public function takeDamage(damage:Float):Void
	{
		currentHealth -= damage;
		if (currentHealth <= 0)
		{
			onDeath();
		}
	}

	function onDeath():Void
	{
		// Base 25% drop rate, scaled by player luck
		var dropChance = 25.0 * PlayState.current.player.luck;
		if (FlxG.random.bool(dropChance))
		{
			PlayState.current.spawnHeart(mp);
		}

		kill();
	}

	override function kill():Void
	{
		super.kill();

		if (shadow != null)
		{
			shadow.kill();
		}
	}
}
