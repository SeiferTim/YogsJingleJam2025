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
	var hasHitThisJab:Bool = false; // Track if current jab dealt damage

	public function new(Owner:FlxSprite, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Owner, Projectiles);
		cooldown = 0.4;
		baseDamage = 14.0;
		maxChargeTime = 1.5;

		jabHitbox = new FlxSprite();
		jabHitbox.loadGraphic("assets/images/halberd-jab.png");
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
			hasHitThisJab = false; // Reset for next jab
		}
	}

	override function fire():Void
	{
		// If charged (held ≥ 1s), do multi-jab (Player only, Ghosts do single jab)
		// Otherwise single jab
		if (getChargePercent() > 0 && Std.isOfType(owner, Player))
		{
			// Calculate number of jabs based on charge (1-5 jabs)
			var chargePercent = getChargePercent();
			multiJabMax = Math.floor(1 + chargePercent * 4); // 1 to 5 jabs
			multiJabCount = multiJabMax;
			multiJabTimer = 0;
		}
		else
		{
			performJab();
		}
	}

	public function jab():Void
	{
		performJab();
	}

	function performJab():Void
	{
		isJabbing = true;
		hasHitThisJab = false; // Reset damage tracking for new jab

		// Create jab hitbox at reach distance
		jabHitbox.exists = true;
		jabHitbox.alpha = 1.0;

		// Position at reach distance in facing direction
		var facingAngle = getOwnerFacingAngle();
		jabHitbox.x = getOwnerX() + getOwnerWidth() / 2 + Math.cos(facingAngle) * jabReach - jabHitbox.width / 2;
		jabHitbox.y = getOwnerY() + getOwnerHeight() / 2 + Math.sin(facingAngle) * jabReach - jabHitbox.height / 2;

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
	public function canDealDamage():Bool
	{
		return !hasHitThisJab;
	}

	public function markHit():Void
	{
		hasHitThisJab = true;
	}
}
