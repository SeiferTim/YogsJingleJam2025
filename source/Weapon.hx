package;

import flixel.group.FlxGroup;

class Weapon
{
	public var cooldown:Float;
	public var baseDamage:Float;
	public var cooldownTimer:Float = 0;

	// Charge mechanics (used by all weapons)
	public var chargeTime:Float = 0;
	public var maxChargeTime:Float = 1.0;
	public var isCharging:Bool = false;
	public var chargeDelay:Float = 0.5;
	public var chargeDelayTimer:Float = 0;

	var player:Player;
	var projectiles:FlxTypedGroup<Projectile>;

	public function new(Player:Player, Projectiles:FlxTypedGroup<Projectile>)
	{
		player = Player;
		projectiles = Projectiles;
		cooldown = 1.0;
		baseDamage = 1.0;
	}

	public function update(elapsed:Float):Void
	{
		if (cooldownTimer > 0)
			cooldownTimer -= elapsed;

		if (isCharging)
		{
			chargeDelayTimer += elapsed;
			if (chargeDelayTimer >= chargeDelay)
			{
				chargeTime += elapsed;
				if (chargeTime > maxChargeTime)
					chargeTime = maxChargeTime;
			}
		}
	}

	public function tap():Void
	{
		// Override in subclasses
	}

	public function startCharge():Void
	{
		if (!canFire())
			return;

		isCharging = true;
		chargeTime = 0;
		chargeDelayTimer = 0;
	}

	public function releaseCharge():Void
	{
		if (!isCharging)
			return;

		isCharging = false;
		chargeTime = 0;
		chargeDelayTimer = 0;
		cooldownTimer = cooldown * player.attackCooldown;
	}

	public function canFire():Bool
	{
		return cooldownTimer <= 0;
	}

	public function getChargePercent():Float
	{
		return Math.min(chargeTime / maxChargeTime, 1.0);
	}

	public function getChargePowerMultiplier():Float
	{
		return 1.0 + getChargePercent();
	}
}
