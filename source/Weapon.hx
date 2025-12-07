package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;

/**
 * Base weapon class - Simple and focused
 * Each weapon has: cooldown, damage, and charge behavior
 * Charge threshold: hold for 1s to charge, release before 1s = tap
 * 
 * Works with any FlxSprite owner (Player or Ghost)
 */
class Weapon
{
	public var cooldown:Float;
	public var baseDamage:Float;
	public var cooldownTimer:Float = 0;
	public var chargeTime:Float = 0;
	public var maxChargeTime:Float = 1.0;
	public var isCharging:Bool = false;
	public static var CHARGE_THRESHOLD:Float = 0.2; // 0.2 second delay before charging begins

	public var owner:FlxSprite; // Can be Player or Ghost
	var projectiles:FlxTypedGroup<Projectile>;

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		owner = Owner;
		projectiles = Projectiles;
		cooldown = 1.0;
		baseDamage = 1.0;
	}

	// Helper methods to get owner properties (works for both Player and Ghost)
	function getOwnerX():Float
	{
		return owner.x;
	}

	function getOwnerY():Float
	{
		return owner.y;
	}

	function getOwnerWidth():Float
	{
		return owner.width;
	}

	function getOwnerHeight():Float
	{
		return owner.height;
	}

	function getOwnerFacingAngle():Float
	{
		if (Std.isOfType(owner, Player))
			return cast(owner, Player).facingAngle;
		else if (Std.isOfType(owner, Ghost))
			return cast(owner, Ghost).facingAngle;
		return 0;
	}

	function getOwnerAttackDamage():Float
	{
		if (Std.isOfType(owner, Player))
			return cast(owner, Player).attackDamage;
		else if (Std.isOfType(owner, Ghost))
			return 1.0; // Ghosts always deal 1.0 damage per hit
		return 1.0;
	}

	function getOwnerMoveSpeed():Float
	{
		if (Std.isOfType(owner, Player))
			return cast(owner, Player).moveSpeed;
		else if (Std.isOfType(owner, Ghost))
			return cast(owner, Ghost).characterData.moveSpeed;
		return 1.0;
	}

	public function update(elapsed:Float):Void
	{
		if (cooldownTimer > 0)
			cooldownTimer -= elapsed;

		// Only accumulate charge time AFTER threshold is passed
		if (isCharging)
		{
			chargeTime += elapsed;
			// Cap at threshold + maxChargeTime
			if (chargeTime > CHARGE_THRESHOLD + maxChargeTime)
				chargeTime = CHARGE_THRESHOLD + maxChargeTime;
		}
	}

	public function startCharge():Void
	{
		if (cooldownTimer <= 0)
		{
			isCharging = true;
			chargeTime = 0;
		}
	}

	public function releaseCharge():Void
	{
		if (isCharging)
		{
			// Fire on release only if held past threshold (charge attack)
			if (chargeTime >= CHARGE_THRESHOLD)
			{
				fire();
				cooldownTimer = cooldown / (1.0 + getOwnerMoveSpeed() * 0.5);
			}
			else if (cooldownTimer <= 0)
			{
				// Quick tap - fire immediately
				fire();
				cooldownTimer = cooldown / (1.0 + getOwnerMoveSpeed() * 0.5);
			}

			isCharging = false;
			chargeTime = 0;
		}
	}

	public function cancelCharge():Void
	{
		// Cancel charge without firing
		isCharging = false;
		chargeTime = 0;
	}

	public function tap():Void
	{
		// Tap attacks fire immediately on press (not on release)
		if (cooldownTimer <= 0)
		{
			fire();
			cooldownTimer = cooldown / (1.0 + getOwnerMoveSpeed() * 0.5);
		}
	}

	public function fire():Void
	{
		// Override in subclasses
	}

	public function getChargePercent():Float
	{
		// No charge until threshold is passed
		if (chargeTime <= CHARGE_THRESHOLD)
			return 0;
		// After threshold, calculate charge percentage from 0 to 1.0
		var chargeProgress = chargeTime - CHARGE_THRESHOLD;
		return Math.min(chargeProgress / maxChargeTime, 1.0);
	}
}
