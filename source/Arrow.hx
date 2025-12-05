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

	override function fire():Void
	{
		var powerMultiplier = 1.0 + getChargePercent();
		
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
