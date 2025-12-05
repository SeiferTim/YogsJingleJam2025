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
	var isDashing:Bool = false;
	var dashSpeed:Float = 200;
	var dashDistance:Float = 0;
	var maxDashDistance:Float = 64;
	var dashDirection:Float = 0;
	var bounceBack:Bool = false;

	public function new(Player:Player, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(Player, Projectiles);
		cooldown = 0.6;
		baseDamage = 12.0;
		maxChargeTime = 1.0;

		// Create slash hitbox with VISIBLE placeholder (white semi-transparent circle)
		slashHitbox = new FlxSprite();
		slashHitbox.makeGraphic(20, 20, 0x88FFFFFF); // White, 50% transparent
		slashHitbox.exists = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Handle dash movement
		if (isDashing)
		{
			var speed = bounceBack ? dashSpeed * 1.5 : dashSpeed;
			var moveX = Math.cos(dashDirection) * speed * elapsed;
			var moveY = Math.sin(dashDirection) * speed * elapsed;

			player.x += moveX;
			player.y += moveY;
			dashDistance += Math.abs(moveX) + Math.abs(moveY);

			var targetDistance = maxDashDistance * getChargePowerMultiplier();
			if (dashDistance >= targetDistance)
			{
				if (!bounceBack)
				{
					// Start bounce back
					bounceBack = true;
					dashDirection += Math.PI; // Reverse direction
					dashDistance = 0;
				}
				else
				{
					// End dash
					endDash();
				}
			}
		}

		// Update hitbox visibility
		if (slashHitbox.exists && slashHitbox.alpha <= 0)
		{
			slashHitbox.exists = false;
		}
	}

	override function tap():Void
	{
		if (!canFire())
			return;

		// Tap always does sweep, never dash
		sweep();
		cooldownTimer = cooldown * player.attackCooldown;
	}

	override function releaseCharge():Void
	{
		if (!isCharging)
			return;

		// Only dash if actually charged (held for at least 0.3 seconds)
		if (chargeTime >= 0.3)
		{
			dash();
		}
		else
		{
			// Quick release = just sweep
			sweep();
		}

		super.releaseCharge();
	}

	function sweep():Void
	{
		// Create sweep area near player
		slashHitbox.exists = true;
		slashHitbox.alpha = 1.0;

		// Position hitbox in front of player
		var offsetDistance = 12;
		slashHitbox.x = player.x + Math.cos(player.facingAngle) * offsetDistance;
		slashHitbox.y = player.y + Math.sin(player.facingAngle) * offsetDistance;

		// Damage anything in the hitbox
		// Note: Collision will be handled in PlayState

		// Fade out hitbox quickly
		FlxTween.tween(slashHitbox, {alpha: 0}, 0.2);
	}

	function dash():Void
	{
		if (isDashing)
			return;

		isDashing = true;
		bounceBack = false;
		dashDistance = 0;
		dashDirection = player.facingAngle;
		maxDashDistance = 64 * getChargePowerMultiplier();

		// Player is invincible during dash
		player.isInvincible = true;

		// Create dash hitbox
		slashHitbox.exists = true;
		slashHitbox.alpha = 1.0;
		slashHitbox.makeGraphic(Std.int(player.width), Std.int(player.height), FlxColor.TRANSPARENT);
	}

	function endDash():Void
	{
		isDashing = false;
		bounceBack = false;
		player.isInvincible = false;
		slashHitbox.exists = false;
	}

	public function getSlashHitbox():FlxSprite
	{
		return slashHitbox;
	}

	public function isDashActive():Bool
	{
		return isDashing;
	}
}
