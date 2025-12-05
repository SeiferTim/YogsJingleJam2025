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
	var hasHitThisSwing:Bool = false; // Track if this swing already dealt damage

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Owner, Projectiles);
		cooldown = 0.6;
		baseDamage = 12.0;
		maxChargeTime = 1.0;

		// Create slash hitbox - try to load custom graphic, fallback to placeholder
		slashHitbox = new FlxSprite();
		try
		{
			slashHitbox.loadGraphic("assets/images/sword-slash.png");
		}
		catch (e:Dynamic)
		{
			// Fallback to placeholder if sword-slash.png doesn't exist yet
			slashHitbox.makeGraphic(20, 20, 0x88FFFFFF); // White, 50% transparent
		}
		slashHitbox.exists = false;
		// Create spin attack hitbox - try to load custom graphic
		spinHitbox = new FlxSprite();
		try
		{
			spinHitbox.loadGraphic("assets/images/sword-spin.png", true, 32, 32);
			// If it has frames, play animation
			if (spinHitbox.frames.frames.length > 1)
			{
				spinHitbox.animation.add("spin", [for (i in 0...spinHitbox.frames.frames.length) i], 12, true);
			}
		}
		catch (e:Dynamic)
		{
			// Fallback to placeholder - circular slash
			spinHitbox.makeGraphic(32, 32, 0x66FFFFFF); // White, semi-transparent
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
			
			// Keep hitbox centered on owner
			spinHitbox.x = owner.x + owner.width / 2 - spinHitbox.width / 2;
			spinHitbox.y = owner.y + owner.height / 2 - spinHitbox.height / 2;

			// Check for enemy hits
			checkForHits(spinHitbox);

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

		// Position hitbox in front of owner, ROTATED to match facing direction
		var offsetDistance = 12;
		var facingAngle = getOwnerFacingAngle();

		// Position the slash sprite at the owner's center + offset in facing direction
		slashHitbox.x = getOwnerX() + getOwnerWidth() / 2 + Math.cos(facingAngle) * offsetDistance - slashHitbox.width / 2;
		slashHitbox.y = getOwnerY() + getOwnerHeight() / 2 + Math.sin(facingAngle) * offsetDistance - slashHitbox.height / 2;

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
		hasHitThisSwing = false;

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
		spinHitbox.exists = false;
		hasHitThisSwing = false;
	}

	function checkForHits(hitbox:FlxSprite):Void
	{
		// This will be called from PlayState's collision detection
		// We just need to track if we've already hit this spin
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
