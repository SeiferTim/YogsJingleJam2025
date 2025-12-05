package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;

class Wand extends Weapon
{
static inline var CHARGE_THRESHOLD:Float = 1.0;

var baseSpeed:Float = 120;
var sparkTimer:Float = 0;
var sparkInterval:Float = 0.1;

public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
{
super(Owner, Projectiles);
cooldown = 0.3;
baseDamage = 5.0;
maxChargeTime = 3.0;
}

override public function update(elapsed:Float):Void
{
super.update(elapsed);

if (isCharging && chargeTime >= CHARGE_THRESHOLD)
{
sparkTimer += elapsed;
if (sparkTimer >= sparkInterval)
{
sparkTimer = 0;
fireWeakSpark();
}
}
}

override function fire():Void
{
if (getChargePercent() == 0)
{
fireHomingExplosion();
}
sparkTimer = 0;
}

function fireWeakSpark():Void
{
var spark:SparkProjectile = cast projectiles.getFirstAvailable(SparkProjectile);
if (spark == null)
{
spark = new SparkProjectile();
projectiles.add(spark);
}

var facingAngle = getOwnerFacingAngle();
var spread = (Math.random() - 0.5) * 0.8;
var angle = facingAngle + spread;

spark.reset(getOwnerX() + getOwnerWidth() / 2 - spark.width / 2, getOwnerY() + getOwnerHeight() / 2 - spark.height / 2);
spark.damage = baseDamage * getOwnerAttackDamage() * 0.5;

var speed = baseSpeed * 1.5;
spark.velocity.x = Math.cos(angle) * speed;
spark.velocity.y = Math.sin(angle) * speed;
}

function fireHomingExplosion():Void
{
var ball:MagicBallProjectile = cast projectiles.getFirstAvailable(MagicBallProjectile);
if (ball == null)
{
ball = new MagicBallProjectile();
projectiles.add(ball);
}

ball.reset(getOwnerX() + getOwnerWidth() / 2 - ball.width / 2, getOwnerY() + getOwnerHeight() / 2 - ball.height / 2);
ball.damage = baseDamage * getOwnerAttackDamage() * 3.0;
ball.isHoming = true;

var facingAngle = getOwnerFacingAngle();
var speed = baseSpeed;
ball.velocity.x = Math.cos(facingAngle) * speed;
ball.velocity.y = Math.sin(facingAngle) * speed;
}
}

class SparkProjectile extends Projectile
{
	public function new()
	{
		super();
		// Try to load custom graphic, fallback to placeholder
		try
		{
			loadGraphic("assets/images/spark.png");
		}
		catch (e:Dynamic)
		{
			makeGraphic(2, 2, 0xffffff00); // Yellow fallback
		}
		antialiasing = false;
		sticksToWalls = false;
	}

	override function revive():Void
	{
		super.revive();
	}
}class MagicBallProjectile extends Projectile
{
public var isHoming:Bool = false;
var homingStrength:Float = 100;
public var targetEnemy:FlxSprite = null;

	public function new()
	{
		super();
		// Try to load custom graphic, fallback to placeholder
		try
		{
			loadGraphic("assets/images/magic-ball.png");
		}
		catch (e:Dynamic)
		{
			makeGraphic(4, 4, 0xff00ffff); // Cyan fallback
		}
		antialiasing = false;
		sticksToWalls = false;
	}override function update(elapsed:Float):Void
{
super.update(elapsed);

if (!isStuck && isHoming && targetEnemy != null && targetEnemy.alive)
{
var dx = (targetEnemy.x + targetEnemy.width / 2) - (x + width / 2);
var dy = (targetEnemy.y + targetEnemy.height / 2) - (y + height / 2);
var dist = Math.sqrt(dx * dx + dy * dy);

if (dist > 0)
{
dx /= dist;
dy /= dist;

velocity.x += dx * homingStrength * elapsed;
velocity.y += dy * homingStrength * elapsed;

var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
if (currentSpeed > 150)
{
velocity.x = (velocity.x / currentSpeed) * 150;
velocity.y = (velocity.y / currentSpeed) * 150;
}
}
}
}

override function revive():Void
{
super.revive();
isHoming = false;
targetEnemy = null;
}
}
