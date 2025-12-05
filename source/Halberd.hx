package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Halberd extends Weapon
{
	var jabHitbox:FlxSprite;
	var jabReach:Float = 12;
	var isJabbing:Bool = false;
	var multiJabCount:Int = 0;
	var multiJabMax:Int = 1;
	var multiJabTimer:Float = 0;
	var multiJabInterval:Float = 0.15; // Time between jabs

	public function new(Player:Player, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Player, Projectiles);
		cooldown = 0.4;
		baseDamage = 14.0;
		maxChargeTime = 1.5;

		// Create jab hitbox with VISIBLE placeholder (yellow circle)
		jabHitbox = new FlxSprite();
		jabHitbox.makeGraphic(4, 4, 0xFFFFFF00); // Yellow, fully visible
		jabHitbox.exists = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Handle multi-jab sequence
		if (multiJabCount > 0)
		{
			multiJabTimer += elapsed;
			if (multiJabTimer >= multiJabInterval)
			{
				multiJabTimer = 0;
				performJab();
				multiJabCount--;
			}
		}

		// Update hitbox visibility
		if (jabHitbox.exists && jabHitbox.alpha <= 0)
		{
			jabHitbox.exists = false;
			isJabbing = false;
		}
	}

	override function tap():Void
	{
		if (!canFire())
			return;

		performJab();
		cooldownTimer = cooldown * player.attackCooldown;
	}

	override function releaseCharge():Void
	{
		if (!isCharging)
			return;

		// Calculate number of jabs based on charge (1-5 jabs)
		var chargePercent = getChargePercent();
		multiJabMax = Math.floor(1 + chargePercent * 4); // 1 to 5 jabs
		multiJabCount = multiJabMax;
		multiJabTimer = 0;

		super.releaseCharge();
		cooldownTimer = cooldown * player.attackCooldown * 0.5; // Shorter cooldown for multi-jab
	}

	function performJab():Void
	{
		isJabbing = true;

		// Create jab hitbox at reach distance
		jabHitbox.exists = true;
		jabHitbox.alpha = 1.0;

		// Position at reach distance in facing direction
		jabHitbox.x = player.x + player.width / 2 + Math.cos(player.facingAngle) * jabReach - jabHitbox.width / 2;
		jabHitbox.y = player.y + player.height / 2 + Math.sin(player.facingAngle) * jabReach - jabHitbox.height / 2;

		// Quick fade
		FlxTween.tween(jabHitbox, {alpha: 0}, 0.1);
	}

	public function getJabHitbox():FlxSprite
	{
		return jabHitbox;
	}

	public function isJabActive():Bool
	{
		return isJabbing && jabHitbox.exists && jabHitbox.alpha > 0;
	}
}
