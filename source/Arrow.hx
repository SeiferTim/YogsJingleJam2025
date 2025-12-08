package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;

class Arrow extends Weapon
{
	var baseSpeed:Float = 200;

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Owner, Projectiles);
		cooldown = 0.5;
		baseDamage = 10.0;
		maxChargeTime = 1.0;
	}

	override public function tap():Void
	{
		// Check cooldown and set it in base class
		if (cooldownTimer <= 0)
		{
			fireArrow(1.0); // Regular power
			super.tap(); // Let base class handle cooldown and preChargeTime
		}
	}

	override function fire():Void
	{
		// JUSTRELEASED with charge > 0 - Fire charged arrow
		// Power scales from 1.0x to 2.0x based on charge
		var powerMultiplier = 1.0 + getChargePercent();
		fireArrow(powerMultiplier);
	}

	function fireArrow(powerMultiplier:Float):Void
	{
		var arrow:ArrowProjectile = cast projectiles.getFirstAvailable(ArrowProjectile);
		if (arrow == null)
		{
			arrow = new ArrowProjectile();
			projectiles.add(arrow);
		}

		var facingAngle = getOwnerFacingAngle();
		arrow.setup(facingAngle * FlxAngle.TO_DEG, powerMultiplier);
		arrow.reset(getOwnerX() + getOwnerWidth() / 2 - arrow.width / 2, getOwnerY() + getOwnerHeight() / 2 - arrow.height / 2);
		arrow.damage = baseDamage * getOwnerAttackDamage() * powerMultiplier;
		arrow.sticksToWalls = true;

		var speed = baseSpeed * powerMultiplier;
		arrow.velocity.x = Math.cos(facingAngle) * speed;
		arrow.velocity.y = Math.sin(facingAngle) * speed;
		Sound.playSound("arrow_shoot");
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
	override public function revive():Void
	{
		super.revive();
		sticksToWalls = true;
	}
	override public function hitWall():Void
	{
		Sound.playSoundRandom("arrow_hit", 2);
		super.hitWall();
	}
}
