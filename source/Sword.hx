package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Sword extends Weapon
{
	var slashHitbox:FlxSprite;
	var spinHitbox:FlxSprite; // Separate hitbox for spin attack
	var isSpinning:Bool = false;
	var spinDuration:Float = 0;
	var spinTimer:Float = 0;
	var spinHitCooldown:Float = 0; // Cooldown between hits during spin
	var spinHitInterval:Float = 1.0; // 1 second between hits
	var hasHitThisSwing:Bool = false; // Track if this swing already dealt damage

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Owner, Projectiles);
		cooldown = 0.6;
		baseDamage = 12.0;
		maxChargeTime = 1.0;

		// Create slash hitbox
		slashHitbox = new FlxSprite();
		slashHitbox.loadGraphic("assets/images/sword-slash.png");
		// Set origin to left-center (0, height/2) so it rotates from the player's position
		slashHitbox.origin.set(0, slashHitbox.height / 2);
		slashHitbox.exists = false;
		// Create spin attack hitbox
		spinHitbox = new FlxSprite();
		spinHitbox.loadGraphic("assets/images/sword-spin.png", true, 32, 32);
		// If it has frames, play animation
		if (spinHitbox.frames.frames.length > 1)
		{
			spinHitbox.animation.add("spin", [for (i in 0...spinHitbox.frames.frames.length) i], 12, true);
		}
		spinHitbox.exists = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Handle spin attack
		if (isSpinning)
		{
			spinTimer += elapsed;
			
			// Update hit cooldown
			if (spinHitCooldown > 0)
			{
				spinHitCooldown -= elapsed;
			}
			
			// Keep hitbox centered on owner
			spinHitbox.x = owner.x + owner.width / 2 - spinHitbox.width / 2;
			spinHitbox.y = owner.y + owner.height / 2 - spinHitbox.height / 2;

			// End spin when duration expires
			if (spinTimer >= spinDuration)
			{
				endSpin();
			}
		}

		// Update hitbox visibility
		if (slashHitbox.exists && slashHitbox.alpha <= 0)
		{
			slashHitbox.exists = false;
			hasHitThisSwing = false; // Reset for next swing
		}
	}

	override public function startCharge():Void
	{
		// Can't start charging while spinning
		if (isSpinning)
			return;

		// Only proceed if cooldown is ready
		if (cooldownTimer > 0)
			return;

		// Do an immediate sweep on button press AND set cooldown
		if (!isCharging)
		{
			sweep();
			cooldownTimer = cooldown / (1.0 + getOwnerMoveSpeed() * 0.5);

			// Now start charging (ignoring cooldown since we just set it)
			isCharging = true;
			chargeTime = 0;
		}
	}

	override public function releaseCharge():Void
	{
		if (isCharging)
		{
			// If charged enough for spin, do it WITHOUT setting cooldown (already set on press)
			if (chargeTime >= Weapon.CHARGE_THRESHOLD)
			{
				fire(); // This calls spin(), no cooldown needed
			}
			// If released before threshold, sweep already happened on press, don't do anything

			isCharging = false;
			chargeTime = 0;
		}
	}

	override function fire():Void
	{
		// If charged (held ≥ 30% charge time), do spin attack
		// Otherwise just sweep
		if (getChargePercent() >= 0.3)
		{
			spin();
		}
		else
		{
			sweep();
		}
	}

	public function sweep():Void
	{
		// Create sweep area near owner
		slashHitbox.exists = true;
		slashHitbox.alpha = 1.0;
		hasHitThisSwing = false; // Reset damage tracking for new swing

		var facingAngle = getOwnerFacingAngle();

		// Position at player's center (origin is at left-center of slash sprite)
		slashHitbox.x = getOwnerX() + getOwnerWidth() / 2;
		slashHitbox.y = getOwnerY() + getOwnerHeight() / 2;

		// Rotate the slash graphic to match the facing angle (convert radians to degrees)
		slashHitbox.angle = facingAngle * (180 / Math.PI);

		// Damage anything in the hitbox
		// Note: Collision will be handled in PlayState

		// Fade out hitbox quickly
		FlxTween.tween(slashHitbox, {alpha: 0}, 0.2);
	}

	function spin():Void
	{
		if (isSpinning)
			return;

		isSpinning = true;
		spinTimer = 0;
		spinHitCooldown = 0; // Reset hit cooldown

		// Duration scales with charge: 0.3s at minimum to 1.5s at full charge
		var chargePercent = getChargePercent();
		spinDuration = 0.3 + (chargePercent * 1.2);

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

	function endSpin():Void
	{
		isSpinning = false;
		spinTimer = 0;
		spinHitCooldown = 0;
		spinHitbox.exists = false;
	}

	public function canDealSpinDamage():Bool
	{
		return spinHitCooldown <= 0;
	}

	public function markSpinHit():Void
	{
		spinHitCooldown = spinHitInterval; // 1 second cooldown
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
