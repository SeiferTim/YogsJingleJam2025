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
	public var preChargeTime:Float = -1; // -1 = not charging, >= 0 = charging (time before charge begins)
	public var chargeTime:Float = 0; // Actual charge time
	public var maxChargeTime:Float = 1.0;
	public var isCharging:Bool = false;
	public var isPressed:Bool = false; // Track if button is currently held

	public static var CHARGE_DELAY:Float = 0.4; // 0.4 second delay before charging begins (long enough to be intentional)

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

		// PRESSED - accumulate precharge, then charge (ONLY if preChargeTime >= 0, meaning tap succeeded)
		if (isPressed && preChargeTime >= 0)
		{
			if (preChargeTime < CHARGE_DELAY)
			{
				preChargeTime += elapsed;
			}
			else if (chargeTime < maxChargeTime)
			{
				chargeTime += elapsed;
				if (chargeTime > maxChargeTime)
					chargeTime = maxChargeTime;

				// Notify subclasses that charging is happening (for wand sparks, etc)
				onCharging(elapsed);
			}
		}
	}

	public function onCharging(elapsed:Float):Void
	{
		// Override in subclasses to do things while charging (wand sparks)
	}

	public function startCharge():Void
	{
		// Start charging (but only if tap succeeded and set preChargeTime to 0)
		if (!isPressed)
		{
			isPressed = true;
			isCharging = false;
			// Don't reset preChargeTime here - tap() will set it to 0 if it succeeded
			// If tap() failed (cooldown active), preChargeTime stays at -1
			chargeTime = 0;
		}
	}

	public function releaseCharge():Void
	{
		if (isPressed)
		{
			// JUSTRELEASED - IF CHARGE > 0, do charge attack
			if (chargeTime > 0)
			{
				fire();
				cooldownTimer = cooldown / (1.0 + getOwnerMoveSpeed() * 0.5);
			}
			// Reset charge state
			isPressed = false;
			isCharging = false;
			preChargeTime = -1; // Reset to -1 (not charging)
			chargeTime = 0;
		}
	}

	public function cancelCharge():Void
	{
		// Cancel charge without firing
		isPressed = false;
		isCharging = false;
		preChargeTime = -1; // Reset to -1 (not charging)
		chargeTime = 0;
	}

	public function tap():Void
	{
		// JUSTPRESSED - instantly fire basic attack and start cooldown
		// Each weapon overrides this to do its basic attack
		if (cooldownTimer <= 0)
		{
			// Subclass should call doTap() to perform the actual attack
			// Then this base method sets cooldown and enables charging
			cooldownTimer = cooldown / (1.0 + getOwnerMoveSpeed() * 0.5);
			// Set preChargeTime to 0 to allow charging (tap succeeded!)
			preChargeTime = 0;
		}
		// If cooldown active, preChargeTime stays at -1, preventing charging
	}

	public function fire():Void
	{
		// Charge attack - override in subclasses
		// This is called on release if charge > 0
	}

	public function getChargePercent():Float
	{
		// Return charge as percentage from 0 to 1.0
		return Math.min(chargeTime / maxChargeTime, 1.0);
	}
}
