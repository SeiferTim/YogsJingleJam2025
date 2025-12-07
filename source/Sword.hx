package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Sword extends Weapon
{
	var slashHitbox:RotatedSprite; // Use RotatedSprite for proper collision detection
	var spinHitbox:FlxSprite; // Separate hitbox for spin attack
	var isSpinning:Bool = false;
	var spinDuration:Float = 0;
	var spinTimer:Float = 0;
	var hasHitThisSwing:Bool = false; // Track if this swing already dealt damage
	var savedMoveSpeed:Float = 1.0; // Store original move speed during spin
	var ownerMP:FlxPoint;
	var spinFlipCounter:Int = 0; // Counter for flipping sprite during spin

	// Spin deceleration
	var spinDecelerating:Bool = false;
	var spinCurrentSpeed:Float = 0;
	var spinDecelerationRate:Float = 100; // Pixels per second^2

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Owner, Projectiles);
		cooldown = 0.6;
		baseDamage = 12.0;
		maxChargeTime = 2.0; // Increased from 1.0 to 2.0 for longer charge time
		ownerMP = Owner.getMidpoint();
		

		// Create slash hitbox
		slashHitbox = new RotatedSprite(); // Use RotatedSprite for rotation collision
		slashHitbox.loadGraphic("assets/images/sword-slash.png");
		// New graphic is now HALF the previous size (24x30px), drawn for 0 degrees (right).
		// IMPORTANT: do NOT scale or call updateHitbox here — updateHitbox can recenter the origin/pivot
		// and clobber the pivot we rely on for rotation. Keep the sprite at native size and set the
		// origin/pivot explicitly for correct rotation.
		// Origin adjusted for the half-size image: (-0.25, 15.25)
		slashHitbox.origin.set(-0.5, 15.5);
		// Do not call updateHitbox() here — it may change the origin/pivot
		slashHitbox.exists = false;

		// Create spin attack hitbox
		spinHitbox = new FlxSprite();
		spinHitbox.loadGraphic("assets/images/sword-spin.png", true, 42, 34);
		// New spin sprite is 42x34px with 2 frames. No scaling, no rotation needed.
		// Just center it over the player.
		spinHitbox.animation.add("spin", [0, 1], 12, true);
		spinHitbox.exists = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (owner != null)
		{
			ownerMP = owner.getMidpoint();
		}
		// Handle spin attack
		if (isSpinning)
		{
			spinTimer += elapsed;
			
			// Flip sprite every other tick for spin visual effect
			if (Std.isOfType(owner, Player))
			{
				var player = cast(owner, Player);
				spinFlipCounter++;
				if (spinFlipCounter % 2 == 0)
				{
					player.flipX = !player.flipX;
				}
			}

			// Handle velocity during spin
			if (Std.isOfType(owner, Player))
			{
				var player = cast(owner, Player);

				if (spinDecelerating)
				{
					// Decelerate to stop
					spinCurrentSpeed -= spinDecelerationRate * elapsed;
					if (spinCurrentSpeed <= 0)
					{
						spinCurrentSpeed = 0;
						player.velocity.set(0, 0);
						endSpin(); // End when stopped
						return;
					}

					// Maintain velocity direction while decelerating
					var currentSpeed = Math.sqrt(player.velocity.x * player.velocity.x + player.velocity.y * player.velocity.y);
					if (currentSpeed > 1)
					{
						player.velocity.x = (player.velocity.x / currentSpeed) * spinCurrentSpeed;
						player.velocity.y = (player.velocity.y / currentSpeed) * spinCurrentSpeed;
					}
				}
				else if (player.spinBounceActive)
				{
					// During bounce, maintain bounce velocity (already set by applySpinBounce)
					// Don't modify - let it play out
				}
				else
				{
					// Normal spin: FORCE minimum velocity at all times
					var minSpeed = 40 * player.moveSpeed; // baseSpeed * current moveSpeed (already boosted by 1.1)
					var currentSpeed = Math.sqrt(player.velocity.x * player.velocity.x + player.velocity.y * player.velocity.y);

					// ALWAYS enforce minimum speed during spin
					if (currentSpeed < minSpeed - 0.1) // Small epsilon for floating point
					{
						// Use last movement angle as direction
						var moveAngle = player.lastMovementAngle;
						player.velocity.set(Math.cos(moveAngle) * minSpeed, Math.sin(moveAngle) * minSpeed);
					}
				}
			}
			
			// Keep hitbox centered on owner
			spinHitbox.x = ownerMP.x - spinHitbox.width / 2;
			spinHitbox.y = ownerMP.y - spinHitbox.height / 2;

			// End spin when duration expires (start deceleration)
			if (spinTimer >= spinDuration && !spinDecelerating)
			{
				startSpinDeceleration();
			}
		}

		// Update hitbox visibility
		if (slashHitbox.exists && slashHitbox.alpha <= 0)
		{
			slashHitbox.exists = false;
			hasHitThisSwing = false; // Reset for next swing
		}
	}

	override public function tap():Void
	{
		// Can't tap while spinning
		if (isSpinning)
			return;

		// Check cooldown and perform sweep
		if (cooldownTimer <= 0)
		{
			sweep();
			super.tap(); // Let base class handle cooldown and preChargeTime
		}
	}

	override function fire():Void
	{
		// JUSTRELEASED with charge > 0 - Do spin based on charge amount
		// Any charge at all triggers spin, duration scales with charge percentage
		spin();
	}

	public function sweep():Void
	{
		// Create sweep area near owner
		slashHitbox.revive();
		slashHitbox.alpha = 1.0;
		hasHitThisSwing = false; // Reset damage tracking for new swing

		var facingAngle = getOwnerFacingAngle();
		slashHitbox.x = ownerMP.x;
		slashHitbox.y = ownerMP.y - slashHitbox.height / 2;

		slashHitbox.angle = facingAngle * (180 / Math.PI);

		FlxTween.tween(slashHitbox, {alpha: 0}, 0.2);
	}

	function spin():Void
	{
		if (isSpinning)
			return;

		isSpinning = true;
		spinTimer = 0;
		spinFlipCounter = 0; // Reset flip counter
		spinDecelerating = false; // Not decelerating yet

		// Duration scales with charge: 0.3s at minimum to 1.5s at full charge
		var chargePercent = getChargePercent();
		spinDuration = 0.3 + (chargePercent * 1.2);

		// Handle player-specific spin effects
		if (Std.isOfType(owner, Player))
		{
			var player = cast(owner, Player);

			// Save original move speed and boost by 10%
			savedMoveSpeed = player.moveSpeed;
			player.moveSpeed *= 1.1;

			// Make player invincible during spin
			player.isInvincible = true;

			// Apply minimum velocity in last movement direction (like dodge momentum)
			var minSpeed = 40 * player.moveSpeed * 1.1; // baseSpeed * moveSpeed * 1.1
			var moveAngle = player.lastMovementAngle;
			player.velocity.set(Math.cos(moveAngle) * minSpeed, Math.sin(moveAngle) * minSpeed);

			// Store initial speed for deceleration
			spinCurrentSpeed = minSpeed;
		}

		// Create spin hitbox
		spinHitbox.exists = true;
		spinHitbox.alpha = 0.7;

		// Start animation if available
		if (spinHitbox.animation != null && spinHitbox.animation.exists("spin"))
		{
			spinHitbox.animation.play("spin");
		}
		
		// Center on owner
		spinHitbox.x = owner.x + owner.width / 2 - spinHitbox.width / 2;
		spinHitbox.y = owner.y + owner.height / 2 - spinHitbox.height / 2;
	}

	function startSpinDeceleration():Void
	{
		spinDecelerating = true;

		if (Std.isOfType(owner, Player))
		{
			var player = cast(owner, Player);
			// Get current speed for deceleration
			spinCurrentSpeed = Math.sqrt(player.velocity.x * player.velocity.x + player.velocity.y * player.velocity.y);
		}
	}

	function endSpin():Void
	{
		isSpinning = false;
		spinTimer = 0;
		spinHitbox.exists = false;
		spinFlipCounter = 0;
		spinDecelerating = false;

		// Restore player state and apply dizzy
		if (Std.isOfType(owner, Player))
		{
			var player = cast(owner, Player);
			player.moveSpeed = savedMoveSpeed;
			player.isInvincible = false;
			player.velocity.set(0, 0);

			// Dizzy duration is half of spin duration
			var dizzyDuration = spinDuration * 0.5;
			player.startDizzy(dizzyDuration);
		}
	}

	public function getSlashHitbox():FlxSprite
	{
		return slashHitbox;
	}
	public function getSpinHitbox():FlxSprite
	{
		return spinHitbox;
	}

	public function isSpinActive():Bool
	{
		return isSpinning;
	}

	public function canDealDamage():Bool
	{
		return !hasHitThisSwing;
	}

	public function markHit():Void
	{
		hasHitThisSwing = true;
	}
}
