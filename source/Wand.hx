package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;

class Wand extends Weapon
{
	var baseSpeed:Float = 120;
	var sparkTimer:Float = 0;
	var sparkInterval:Float = 0.08; // Fire sparks every 0.08s = ~12/sec

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Owner, Projectiles);
		cooldown = 2.0; // 2 second cooldown between magic balls
		baseDamage = 5.0;
		maxChargeTime = 999.0; // Wand doesn't increase charge, just tracks duration
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Wand doesn't accumulate charge - reset it after sparks start
		// This keeps chargeTime > 0 (so fire() gets called on release) but doesn't grow
		if (chargeTime > 0.1)
			chargeTime = 0.1;
	}

	override public function onCharging(elapsed:Float):Void
	{
		// While charging (after precharge delay), constantly fire sparks
		sparkTimer += elapsed;
		if (sparkTimer >= sparkInterval)
		{
			sparkTimer = 0;
			fireWeakSpark();
		}
	}

	override public function tap():Void
	{
		// Check cooldown and fire
		if (cooldownTimer <= 0)
		{
			fireHomingBall();
			super.tap(); // Let base class handle cooldown and preChargeTime
		}
	}

	override function fire():Void
	{
		// JUSTRELEASED with charge > 0 - Wand doesn't do anything special
		// Sparks already fired during hold
		sparkTimer = 0;
	}

	function fireWeakSpark():Void
	{
		var spark:SparkProjectile = cast projectiles.getFirstAvailable(SparkProjectile);
		if (spark == null)
		{
			spark = new SparkProjectile();
			projectiles.add(spark);
		}

		var facingAngle = getOwnerFacingAngle();
		// Cone spread: ±30 degrees (0.52 radians)
		var spread = (Math.random() - 0.5) * 1.05;
		var angle = facingAngle + spread;

		spark.reset(getOwnerX() + getOwnerWidth() / 2 - spark.width / 2, getOwnerY() + getOwnerHeight() / 2 - spark.height / 2);
		spark.damage = baseDamage * getOwnerAttackDamage() * 0.3; // Weak damage per spark

		// Faster, longer range
		var speed = 120; // Increased from 80
		spark.velocity.x = Math.cos(angle) * speed;
		spark.velocity.y = Math.sin(angle) * speed;
		// Reduced spark lifetime (0.6s)
		spark.maxLifetime = 0.6;
	}

	function fireHomingBall():Void
	{
		var ball:MagicBallProjectile = cast projectiles.getFirstAvailable(MagicBallProjectile);
		if (ball == null)
		{
			ball = new MagicBallProjectile();
			projectiles.add(ball);
		}

		ball.reset(getOwnerX() + getOwnerWidth() / 2 - ball.width / 2, getOwnerY() + getOwnerHeight() / 2 - ball.height / 2);
		ball.damage = baseDamage * getOwnerAttackDamage() * 2.0; // Strong single shot
		ball.isHoming = true;

		var facingAngle = getOwnerFacingAngle();
		// Slow moving
		var speed = 60;
		ball.velocity.x = Math.cos(facingAngle) * speed;
		ball.velocity.y = Math.sin(facingAngle) * speed;
	}
}

class SparkProjectile extends Projectile
{
	public var maxLifetime:Float = 0.8; // Increased from 0.4

	private var lifetime:Float = 0;

	public function new()
	{
		super();
		// Load spritesheet with 2 animation frames
		loadGraphic("assets/images/spark.png", true, 8, 8);
		animation.add("spark", [0, 1], 12, true);
		animation.play("spark");

		// Trim hitbox to 2x2 centered in 8x8 frame
		setSize(2, 2);
		centerOffsets();

		antialiasing = false;
		sticksToWalls = false;
	}
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		lifetime += elapsed;
		if (lifetime >= maxLifetime)
		{
			kill();
		}
	}

	override function revive():Void
	{
		super.revive();
		lifetime = 0;
	}
}

class MagicBallProjectile extends Projectile
{
	public var isHoming:Bool = false;
	var homingStrength:Float = 150; // Increased magnetism

	public var targetEnemy:FlxSprite = null;
	
	// Lifespan for ghost projectiles
	var lifetime:Float = 0;
	var maxLifetime:Float = 0; // 0 = infinite (player), > 0 = limited (ghost)

	public function new()
	{
		super();
		// Load spritesheet with idle and pop animations
		loadGraphic("assets/images/magic-ball.png", true, 8, 8);
		// Frames 0-5 are idle animation, frames 6-7 are pop
		animation.add("idle", [0, 1, 2, 3, 4, 5], 8, true);
		animation.add("pop", [6, 7], 12, false);
		animation.play("idle"); // Set callback for when animation finishes
		animation.onFinish.add((animName:String) ->
		{
			trace("MagicBall animation finished: " + animName);
			if (animName == "pop")
			{
				trace("MagicBall setting exists = false");
				exists = false;
			}
		});

		// Trim hitbox if needed (keep it 8x8 or smaller depending on visual)
		setSize(6, 6);
		centerOffsets();
		
		antialiasing = false;
		sticksToWalls = false;
	}

	override function reset(X:Float, Y:Float):Void
	{
		super.reset(X, Y);
		lifetime = 0;

		// Determine if this is a ghost/boss projectile (has limited lifespan)
		// Check if we're in bossProjectiles group - if so, set lifespan
		if (PlayState.current != null && PlayState.current.bossProjectiles != null)
		{
			var isGhostProjectile = PlayState.current.bossProjectiles.members.indexOf(this) != -1;
			maxLifetime = isGhostProjectile ? 3.0 : 0; // Ghost projectiles last 3 seconds
		}
		else
		{
			maxLifetime = 0; // Player projectiles last forever
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Only do homing logic while alive
		if (!alive)
			return;

		// Track lifetime for ghost projectiles
		if (maxLifetime > 0)
		{
			lifetime += elapsed;
			if (lifetime >= maxLifetime)
			{
				pop(); // Pop instead of instant kill
				return;
			}
		}

		// Find nearest enemy (boss or ghost)
		if (isHoming)
		{
			findNearestEnemy();

			if (targetEnemy != null && targetEnemy.alive)
			{
				// Drift towards target like a magnet
				var dx = (targetEnemy.x + targetEnemy.width / 2) - (x + width / 2);
				var dy = (targetEnemy.y + targetEnemy.height / 2) - (y + height / 2);
				var dist = Math.sqrt(dx * dx + dy * dy);

				if (dist > 0)
				{
					dx /= dist;
					dy /= dist;

					velocity.x += dx * homingStrength * elapsed;
					velocity.y += dy * homingStrength * elapsed;

					// Cap max speed
					var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
					if (currentSpeed > 80) // Slower than before (was 150)
					{
						velocity.x = (velocity.x / currentSpeed) * 80;
						velocity.y = (velocity.y / currentSpeed) * 80;
					}
				}
			}
		}
	}

	function findNearestEnemy():Void
	{
		if (PlayState.current == null)
			return;

		var nearest:FlxSprite = null;
		var nearestDist:Float = Math.POSITIVE_INFINITY;

		// Determine if this is a player projectile or ghost/boss projectile
		// Player projectiles are in PlayState.current.projectiles
		// Ghost/boss projectiles are in PlayState.current.bossProjectiles
		var isPlayerProjectile = PlayState.current.projectiles != null && PlayState.current.projectiles.members.indexOf(this) != -1;

		if (isPlayerProjectile)
		{
			// Player projectiles target: boss, mayflies, ghosts
			// Priority: Boss > Ghosts > Mayflies (by artificially increasing mayfly distance)

			// Check boss (highest priority - no distance penalty)
			if (PlayState.current.boss != null && PlayState.current.boss.currentHealth > 0)
			{
				var boss:BossPhase01Larva = cast PlayState.current.boss;
				var dx = boss.headX - (x + width / 2);
				var dy = boss.headY - (y + height / 2);
				var dist = dx * dx + dy * dy; // Use squared distance for speed

				if (dist < nearestDist)
				{
					nearestDist = dist;
					nearest = boss.headSegment.sprite;
				}
			}

			// Check ghosts (high priority - no distance penalty)
			if (PlayState.current.ghosts != null)
			{
				PlayState.current.ghosts.forEachAlive(function(ghost:Ghost)
				{
					var dx = ghost.x + ghost.width / 2 - (x + width / 2);
					var dy = ghost.y + ghost.height / 2 - (y + height / 2);
					var dist = dx * dx + dy * dy;

					if (dist < nearestDist)
					{
						nearestDist = dist;
						nearest = ghost;
					}
				});
			}

			// Check mayflies (lower priority - apply 3x distance penalty to make them less attractive)
			if (PlayState.current.mayflies != null)
			{
				PlayState.current.mayflies.forEachAlive(function(mayfly:Mayfly)
				{
					var dx = mayfly.x + mayfly.width / 2 - (x + width / 2);
					var dy = mayfly.y + mayfly.height / 2 - (y + height / 2);
					var dist = (dx * dx + dy * dy) * 3.0; // 3x penalty makes them less attractive

					if (dist < nearestDist)
					{
						nearestDist = dist;
						nearest = mayfly;
					}
				});
			}
		}
		else
		{
			// Ghost/boss projectiles ONLY target the player
			if (PlayState.current.player != null && PlayState.current.player.alive)
			{
				nearest = PlayState.current.player;
			}
		}
		targetEnemy = nearest;
	}

	override public function hitWall():Void
	{
		pop();
	}

	override public function hitEnemy():Void
	{
		pop();
	}
	public function pop():Void
	{
		if (!alive)
		{
			trace("MagicBall.pop() called but already dead");
			return;
		}
		trace("MagicBall.pop() - Starting pop animation");
		alive = false;
		exists = true;
		velocity.set(0, 0);
		animation.play("pop", true);
	}
	override public function kill():Void
	{
		super.kill();
		targetEnemy = null;
		isHoming = false;
	}

	override function revive():Void
	{
		super.revive();
		isHoming = false;
		targetEnemy = null;
		animation.play("idle");
	}
}
