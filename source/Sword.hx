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
	var slashHitbox:FlxSprite; // Regular sprite with loadRotatedGraphic for collision
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

	// Worldbounds bounce cooldown
	var lastBounceTime:Float = 0;
	var bounceCooldown:Float = 0.2; // Minimum time between wall bounces

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Owner, Projectiles);
		cooldown = 0.6;
		baseDamage = 12.0;
		maxChargeTime = 2.0; // Increased from 1.0 to 2.0 for longer charge time
		ownerMP = Owner.getMidpoint();
		

		// Create slash hitbox with rotated graphics for proper collision at all angles
		// New 54x54px sprite with 24x30 slash drawn on one side - rotates around center
		slashHitbox = new FlxSprite();
		slashHitbox.loadRotatedGraphic("assets/images/sword-slash.png", 36, -1, false, false); // 36 angles for smoother rotation
		slashHitbox.antialiasing = false;
		// Origin at center - sprite will rotate around player's center
		slashHitbox.origin.set(slashHitbox.width / 2, slashHitbox.height / 2);
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

				if (player.spinBounceActive)
				{
					// During bounce (0.3s after hitting wall), lock to bounce direction
					// Player can't change direction - just maintain bounce velocity
					// spinBounceActive will auto-expire after spinBounceDuration
				}
				else if (spinDecelerating)
				{
					// Decelerate to stop, but allow player to change direction
					spinCurrentSpeed -= spinDecelerationRate * elapsed;
					if (spinCurrentSpeed <= 0)
					{
						spinCurrentSpeed = 0;
						player.velocity.set(0, 0);
						endSpin(); // End when stopped
						return;
					}

					// Get player input for direction
					var moveX = Actions.leftStick.x != 0 ? Actions.leftStick.x : (Actions.right.triggered ? 1 : (Actions.left.triggered ? -1 : 0));
					var moveY = Actions.leftStick.y != 0 ? Actions.leftStick.y : (Actions.down.triggered ? 1 : (Actions.up.triggered ? -1 : 0));

					var moveAngle:Float;
					if (moveX != 0 || moveY != 0)
					{
						// Player is giving input - use that direction
						moveAngle = Math.atan2(moveY, moveX);
						player.lastMovementAngle = moveAngle; // Update for future use
					}
					else
					{
						// No input - maintain current velocity direction
						var currentSpeed = Math.sqrt(player.velocity.x * player.velocity.x + player.velocity.y * player.velocity.y);
						if (currentSpeed > 1)
						{
							moveAngle = Math.atan2(player.velocity.y, player.velocity.x);
						}
						else
						{
							moveAngle = player.lastMovementAngle;
						}
					}
					// Apply decelerating speed in the chosen direction
					player.velocity.set(Math.cos(moveAngle) * spinCurrentSpeed, Math.sin(moveAngle) * spinCurrentSpeed);
				}
				else
				{
					// Normal spin: Allow player to change direction, but lock speed
					var lockedSpeed = 40 * player.moveSpeed * 1.1; // baseSpeed * moveSpeed * spin boost

					// Get player input
					var moveX = Actions.leftStick.x != 0 ? Actions.leftStick.x : (Actions.right.triggered ? 1 : (Actions.left.triggered ? -1 : 0));
					var moveY = Actions.leftStick.y != 0 ? Actions.leftStick.y : (Actions.down.triggered ? 1 : (Actions.up.triggered ? -1 : 0));

					if (moveX != 0 || moveY != 0)
					{
						// Player is giving input - use that direction but lock speed
						var inputAngle = Math.atan2(moveY, moveX);
						player.lastMovementAngle = inputAngle; // Update for next bounce/dodge
						player.velocity.set(Math.cos(inputAngle) * lockedSpeed, Math.sin(inputAngle) * lockedSpeed);
					}
					else
					{
						// No input - use last movement angle at locked speed
						var moveAngle = player.lastMovementAngle;
						player.velocity.set(Math.cos(moveAngle) * lockedSpeed, Math.sin(moveAngle) * lockedSpeed);
					}
				}
			}
			
			// Keep hitbox centered on owner
			spinHitbox.x = ownerMP.x - spinHitbox.width / 2;
			spinHitbox.y = ownerMP.y - spinHitbox.height / 2;

			// Check worldbounds collision and bounce (with cooldown to prevent getting stuck)
			// Use spinHitbox position instead of player position for blade collision
			if (Std.isOfType(owner, Player))
			{
				var player = cast(owner, Player);
				var currentTime = spinTimer;

				// Only check for bounces if enough time has passed since last bounce
				if (currentTime - lastBounceTime >= bounceCooldown)
				{
					var bounced = false;

					// Check left/right bounds using spin hitbox edges
					if (spinHitbox.x <= FlxG.worldBounds.x)
					{
						// Hit left wall - reflect X velocity
						player.applySpinBounce(-player.velocity.x, player.velocity.y);
						lastBounceTime = currentTime;
						bounced = true;
					}
					else if (spinHitbox.x + spinHitbox.width >= FlxG.worldBounds.right)
					{
						// Hit right wall - reflect X velocity
						player.applySpinBounce(-player.velocity.x, player.velocity.y);
						lastBounceTime = currentTime;
						bounced = true;
					}

					// Check top/bottom bounds (only if didn't already bounce on X)
					if (!bounced)
					{
						if (spinHitbox.y <= FlxG.worldBounds.y)
						{
							// Hit top wall - reflect Y velocity
							player.applySpinBounce(player.velocity.x, -player.velocity.y);
							lastBounceTime = currentTime;
						}
						else if (spinHitbox.y + spinHitbox.height >= FlxG.worldBounds.bottom)
						{
							// Hit bottom wall - reflect Y velocity
							player.applySpinBounce(player.velocity.x, -player.velocity.y);
							lastBounceTime = currentTime;
						}
					}
				}
			}

			// End spin when duration expires (start deceleration)
			if (spinTimer >= spinDuration && !spinDecelerating)
			{
				startSpinDeceleration();
			}
		}

		// Update slash hitbox position to follow owner while active
		if (slashHitbox.exists && slashHitbox.alpha > 0)
		{
			var facingAngle = getOwnerFacingAngle();
			// Position at owner midpoint
			slashHitbox.x = ownerMP.x - slashHitbox.origin.x;
			slashHitbox.y = ownerMP.y - slashHitbox.origin.y;
			// Set angle - RotatedSprite handles the rotation properly with loadRotatedGraphic
			slashHitbox.angle = facingAngle * (180 / Math.PI);
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
		// Position at owner midpoint, accounting for origin
		slashHitbox.x = ownerMP.x - slashHitbox.origin.x;
		slashHitbox.y = ownerMP.y - slashHitbox.origin.y;
		slashHitbox.angle = facingAngle * (180 / Math.PI);

		Sound.playSoundRandom("sword_sweep", 2);

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
		lastBounceTime = 0; // Reset bounce cooldown for new spin

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
		Sound.playSound("sword_spin");
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
	/**
	 * Check if a target sprite is hit by the sword slash using angle-based collision.
	 * Works correctly with rotated sprites unlike pixelPerfectOverlap.
	 * @param target The sprite to check collision against
	 * @return True if the target is within the slash arc
	 */
	public function checkSlashHit(target:FlxSprite):Bool
	{
		if (!slashHitbox.exists || slashHitbox.alpha <= 0)
			return false;

		// First check: basic bounding box overlap
		if (!slashHitbox.overlaps(target))
			return false;

		// Get target center point
		var targetMP = target.getMidpoint();

		// Calculate distance from player center to target center
		var dx = targetMP.x - ownerMP.x;
		var dy = targetMP.y - ownerMP.y;
		var distance = Math.sqrt(dx * dx + dy * dy);

		// Slash reaches about 30px from center (based on 24x30 graphic in 54x54 sprite)
		// Add target's radius for more generous collision
		var maxDistance = 30 + Math.max(target.width, target.height) / 2;

		if (distance > maxDistance)
			return false;

		// Calculate angle from player to target
		var targetAngle = Math.atan2(dy, dx);

		// Get current slash angle (convert from degrees to radians)
		var slashAngle = slashHitbox.angle * (Math.PI / 180);

		// Normalize angles to -PI to PI range
		while (targetAngle - slashAngle > Math.PI)
			targetAngle -= Math.PI * 2;
		while (targetAngle - slashAngle < -Math.PI)
			targetAngle += Math.PI * 2;

		// Check if target is within slash arc (±45 degrees = ±PI/4 radians)
		var angleDiff = Math.abs(targetAngle - slashAngle);
		var arcWidth = Math.PI / 4; // 45 degrees on each side

		targetMP.put();

		return angleDiff <= arcWidth;
	}
}
