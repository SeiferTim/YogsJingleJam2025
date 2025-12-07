package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;

class Plasma extends FlxSprite
{
	public var isExploding:Bool = false;
	public var isCharging:Bool = false; // New: tracks if plasma is charging in boss mouth

	private var speed:Float = 40; // Slower for better visibility
	private var turnSpeed:Float = 60; // Degrees per second - slow turning
	private var lifeTimer:Float = 0;
	private var maxLifeTime:Float = 2.5; // 2-3 seconds (average)
	private var player:Player;

	public var onExplode:Plasma->Void;

	public function new()
	{
		super();
		loadGraphic("assets/images/plasma.png", true, 8, 8);
		animation.add("idle", [0, 1], 6, true);
		animation.play("idle");

		setSize(6, 6);
		centerOffsets();

		active = false;
		exists = false;
	}

	public function spawn(X:Float, Y:Float, target:Player):Void
	{
		reset(X - width / 2, Y - height / 2);
		active = true;
		exists = true;
		visible = true;
		isExploding = false;
		isCharging = false;
		lifeTimer = 0;
		maxLifeTime = 2 + Math.random(); // Random 2-3 seconds
		player = target;

		animation.play("idle");
	}

	// New: Start charging phase (sits in boss mouth)
	public function startCharging(X:Float, Y:Float):Void
	{
		reset(X - width / 2, Y - height / 2);
		active = true;
		exists = true;
		visible = true;
		isExploding = false;
		isCharging = true;
		lifeTimer = 0;
		velocity.set(0, 0); // No movement while charging

		animation.play("idle");
	}

	// New: Launch the plasma towards player
	public function launch(target:Player):Void
	{
		isCharging = false;
		player = target;
		maxLifeTime = 2 + Math.random(); // Random 2-3 seconds

		// Initial velocity towards player
		if (player != null && player.alive)
		{
			var dirX = player.x + player.width / 2 - (x + width / 2);
			var dirY = player.y + player.height / 2 - (y + height / 2);
			var dist = Math.sqrt(dirX * dirX + dirY * dirY);

			if (dist > 0)
			{
				velocity.x = (dirX / dist) * speed;
				velocity.y = (dirY / dist) * speed;
			}
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!active || isExploding || isCharging)
			return; // Don't update movement while charging

		// Homing behavior - gradually turn towards player (not instant)
		if (player != null && player.alive)
		{
			var currentAngle = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
			var targetAngle = Math.atan2(player.y + player.height / 2 - (y + height / 2), player.x + player.width / 2 - (x + width / 2)) * 180 / Math.PI;

			// Calculate shortest angle difference
			var angleDiff = targetAngle - currentAngle;
			while (angleDiff > 180)
				angleDiff -= 360;
			while (angleDiff < -180)
				angleDiff += 360;

			// Turn towards target at turnSpeed
			var turnAmount = Math.min(Math.abs(angleDiff), turnSpeed * elapsed);
			if (angleDiff < 0)
				turnAmount = -turnAmount;

			var newAngle = (currentAngle + turnAmount) * Math.PI / 180;
			velocity.x = Math.cos(newAngle) * speed;
			velocity.y = Math.sin(newAngle) * speed;
		}

		// Life timer - explode after max time
		lifeTimer += elapsed;
		if (lifeTimer >= maxLifeTime)
		{
			explode();
			return;
		}

		// Check world bounds - explode if hitting edge
		if (x < FlxG.worldBounds.left || x + width > FlxG.worldBounds.right || y < FlxG.worldBounds.top || y + height > FlxG.worldBounds.bottom)
		{
			explode();
		}
	}

	public function explode():Void
	{
		if (isExploding)
			return;

		isExploding = true;
		velocity.set(0, 0);

		// Load explosion graphic centered on plasma
		var explosionX = x + width / 2 - 32; // Center 64px explosion on 8px plasma
		var explosionY = y + height / 2 - 32;

		loadGraphic("assets/images/plasma-explosion.png", true, 64, 64);
		animation.add("explode", [0, 1], 12, false);
		setPosition(explosionX, explosionY);
		setSize(64, 64);
		centerOffsets();
		animation.play("explode");

		// Trigger callback
		if (onExplode != null)
			onExplode(this);

		// Kill after explosion animation completes (0.5 seconds)
		new FlxTimer().start(0.5, function(_)
		{
			kill();
		});
	}

	override public function kill():Void
	{
		active = false;
		exists = false;
		visible = false;
		isExploding = false;
		isCharging = false;
		player = null;
	}
}
