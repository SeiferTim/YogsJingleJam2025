package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;

class Wand extends Weapon
{
	var baseSpeed:Float = 120; // Slower than arrows

	public function new(Player:Player, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Player, Projectiles);
		cooldown = 0.8; // Slower fire rate
		baseDamage = 15.0; // More damage than bow
		maxChargeTime = 2.0; // Longer charge time
	}

	override function tap():Void
	{
		if (!canFire())
			return;

		fireHomingBall();
		cooldownTimer = cooldown * player.attackCooldown;
	}

	override function releaseCharge():Void
	{
		if (!isCharging)
			return;

		fireFireball(getChargePowerMultiplier());
		super.releaseCharge();
		cooldownTimer = cooldown * player.attackCooldown * 2.0; // Long cooldown for fireball
	}

	function fireHomingBall():Void
	{
		var ball:MagicBallProjectile = cast projectiles.getFirstAvailable(MagicBallProjectile);
		if (ball == null)
		{
			ball = new MagicBallProjectile();
			projectiles.add(ball);
		}

		ball.reset(player.x + player.width / 2 - ball.width / 2, player.y + player.height / 2 - ball.height / 2);
		ball.damage = baseDamage * player.attackDamage;
		ball.isHoming = true;

		// Initial velocity in facing direction
		var speed = baseSpeed;
		ball.velocity.x = Math.cos(player.facingAngle) * speed;
		ball.velocity.y = Math.sin(player.facingAngle) * speed;
	}

	function fireFireball(powerMultiplier:Float):Void
	{
		var fireball:FireballProjectile = cast projectiles.getFirstAvailable(FireballProjectile);
		if (fireball == null)
		{
			fireball = new FireballProjectile();
			projectiles.add(fireball);
		}

		fireball.reset(player.x + player.width / 2 - fireball.width / 2, player.y + player.height / 2 - fireball.height / 2);
		fireball.damage = baseDamage * player.attackDamage * powerMultiplier * 1.5;
		fireball.burnDuration = 2.0 * powerMultiplier; // Longer burn = longer charge

		var speed = baseSpeed * 0.8; // Slower than magic ball
		fireball.velocity.x = Math.cos(player.facingAngle) * speed;
		fireball.velocity.y = Math.sin(player.facingAngle) * speed;

		// Scale fireball with charge
		var scale = 1.0 + (powerMultiplier - 1.0) * 0.5;
		fireball.scale.set(scale, scale);
	}
}

class MagicBallProjectile extends Projectile
{
	public var isHoming:Bool = false;

	var homingStrength:Float = 100;

	public var targetEnemy:FlxSprite = null; // Reference to current target

	public function new()
	{
		super();
		makeGraphic(4, 4, 0xff00ffff); // Cyan ball
		antialiasing = false;
		sticksToWalls = false;
		sticksToEnemies = false;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isStuck && isHoming && targetEnemy != null && targetEnemy.alive)
		{
			// Steer toward target
			var dx = (targetEnemy.x + targetEnemy.width / 2) - (x + width / 2);
			var dy = (targetEnemy.y + targetEnemy.height / 2) - (y + height / 2);
			var dist = Math.sqrt(dx * dx + dy * dy);

			if (dist > 0)
			{
				// Normalize
				dx /= dist;
				dy /= dist;

				// Steer velocity toward target
				velocity.x += dx * homingStrength * elapsed;
				velocity.y += dy * homingStrength * elapsed;

				// Clamp speed
				var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
				if (currentSpeed > 150)
				{
					velocity.x = (velocity.x / currentSpeed) * 150;
					velocity.y = (velocity.y / currentSpeed) * 150;
				}
			}
		}
	}

	override function revive():Void
	{
		super.revive();
		isHoming = false;
		targetEnemy = null;
	}
}

class FireballProjectile extends Projectile
{
	public var burnDuration:Float = 2.0;
	public var burnDamagePerSecond:Float = 2.0;

	public function new()
	{
		super();
		makeGraphic(6, 6, 0xffff4400); // Orange fireball
		antialiasing = false;
		sticksToWalls = false;
		sticksToEnemies = false;
	}

	override function revive():Void
	{
		super.revive();
		burnDuration = 2.0;
		burnDamagePerSecond = 2.0;
		scale.set(1, 1);
	}
}
