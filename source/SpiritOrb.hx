package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;

/**
 * Spirit orbs are dropped when ghosts are defeated.
 * They float toward the player and level up their stats when collected.
 */
class SpiritOrb extends FlxSprite
{
	public var isActive:Bool = false;
	public var onCollect:Void->Void; // Callback when orb is collected

	var floatTimer:Float = 0;
	var floatAmplitude:Float = 4;
	var floatFrequency:Float = 2;
	var moveTowardPlayerDelay:Float = 0.5; // Delay before orb starts moving toward player
	var moveDelay:Float = 0;
	var targetPlayer:Player;

	public function new()
	{
		super();

		// Load the spirit orb sprite (8x8, 2 frames)
		loadGraphic("assets/images/spirit-orb.png", true, 8, 8);

		// Set up fast pulse animation
		animation.add("pulse", [0, 1], 12, true); // 12 fps for fast pulse
		animation.play("pulse");

		// Set up facing flip (sprite faces right by default)
		setFacingFlip(RIGHT, false, false);
		setFacingFlip(LEFT, true, false);

		// Smaller hitbox (6x6 centered within the 8x8 sprite)
		setSize(6, 6);
		offset.set(1, 1); // Center the 6x6 hitbox within the 8x8 sprite

		antialiasing = false;
		isActive = false;
		exists = false;
		alpha = 0.7; // Semi-transparent
	}

	public function spawn(X:Float, Y:Float, player:Player):Void
	{
		x = X - width / 2; // Center on spawn position
		y = Y - height / 2;
		isActive = true;
		exists = true;
		visible = true;
		alpha = 0.7; // Semi-transparent
		floatTimer = 0;
		moveDelay = moveTowardPlayerDelay;
		targetPlayer = player;

		// Add a small scale-in effect
		scale.set(0.1, 0.1);
		FlxTween.tween(scale, {x: 1, y: 1}, 0.3);
	}

	public function despawn():Void
	{
		isActive = false;
		exists = false;
		visible = false;
		targetPlayer = null;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isActive)
			return;

		// Floating animation
		floatTimer += elapsed;
		var floatOffset = Math.sin(floatTimer * floatFrequency * Math.PI * 2) * floatAmplitude;
		y += floatOffset * elapsed * 10;

		// After delay, move toward player
		if (moveDelay > 0)
		{
			moveDelay -= elapsed;
		}
		else if (targetPlayer != null && targetPlayer.exists)
		{
			// Accelerate toward player
			var dx = targetPlayer.x + targetPlayer.width / 2 - (x + width / 2);
			var dy = targetPlayer.y + targetPlayer.height / 2 - (y + height / 2);
			var distance = Math.sqrt(dx * dx + dy * dy);

			if (distance > 2)
			{
				var speed = 120 + (1.0 - Math.min(distance, 100) / 100) * 180; // Speed up as it gets closer
				var vx = (dx / distance) * speed;
				var vy = (dy / distance) * speed;
				velocity.set(vx, vy);

				// Update facing direction based on movement
				facing = (vx < 0) ? LEFT : RIGHT;
			}
			else
			{
				// Close enough to collect
				collect();
			}
		}
	}

	function collect():Void
	{
		if (targetPlayer == null || !targetPlayer.exists)
		{
			despawn();
			return;
		}

		// Level up a random stat
		var statChoice = FlxG.random.int(0, 2);
		var statIncrement = 0.1; // 10% increase per orb

		switch (statChoice)
		{
			case 0: // Attack damage
				targetPlayer.attackDamage += statIncrement;
				trace("Spirit Orb collected! Attack Damage: " + targetPlayer.attackDamage);

			case 1: // Move speed
				targetPlayer.moveSpeed += statIncrement;
				trace("Spirit Orb collected! Move Speed: " + targetPlayer.moveSpeed);

			case 2: // Luck
				targetPlayer.luck += statIncrement;
				trace("Spirit Orb collected! Luck: " + targetPlayer.luck);
		}

		// Flash the player to show level up
		FlxG.camera.flash(FlxColor.WHITE, 0.15);

		// TODO: Play collection sound effect
		// FlxG.sound.play("assets/sounds/orb_collect.wav");

		// Trigger callback if set
		if (onCollect != null)
			onCollect();

		despawn();
	}
}
