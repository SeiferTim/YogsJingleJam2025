package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;

class Arrow extends Weapon
{
	var baseSpeed:Float = 200;

	public function new(Player:Player, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Player, Projectiles);
		cooldown = 0.5;
		baseDamage = 10.0;
		maxChargeTime = 1.0;
	}

	override function tap():Void
	{
		if (!canFire())
			return;

		fire(1.0);
		cooldownTimer = cooldown * player.attackCooldown;
	}

	override function releaseCharge():Void
	{
		if (!isCharging)
			return;

		fire(getChargePowerMultiplier());
		super.releaseCharge();
	}

	function fire(powerMultiplier:Float):Void
	{
		var arrow:ArrowProjectile = cast projectiles.getFirstAvailable(ArrowProjectile);
		if (arrow == null)
		{
			arrow = new ArrowProjectile();
			projectiles.add(arrow);
		}

		arrow.setup(player.facingAngle * FlxAngle.TO_DEG, powerMultiplier);
		arrow.reset(player.x + player.width / 2 - arrow.width / 2, player.y + player.height / 2 - arrow.height / 2);
		arrow.damage = baseDamage * player.attackDamage * powerMultiplier;

		var speed = baseSpeed * powerMultiplier;
		arrow.velocity.x = Math.cos(player.facingAngle) * speed;
		arrow.velocity.y = Math.sin(player.facingAngle) * speed;
	}
}

class ArrowProjectile extends Projectile
{
	public function new()
	{
		super();
		loadRotatedGraphic("assets/images/arrow.png", 32, -1, false, true);
		antialiasing = false;
		width = 2;
		height = 2;
	}

	public function setup(degrees:Float, scale:Float):Void
	{
		angle = degrees;
		this.scale.set(scale, scale);
		updateTipHitbox(degrees);
	}

	function updateTipHitbox(degrees:Float):Void
	{
		var radians = degrees * Math.PI / 180;
		var tipOffsetX = Math.cos(radians) * (frameWidth / 2 - 1);
		var tipOffsetY = Math.sin(radians) * (frameWidth / 2 - 1);

		offset.x = (frameWidth / 2) + tipOffsetX - (width / 2);
		offset.y = (frameHeight / 2) + tipOffsetY - (height / 2);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isStuck && angle != 0)
		{
			updateTipHitbox(angle);
		}
	}
}
