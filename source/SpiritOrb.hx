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
class SpiritOrb extends GameEntity
{
	public var isActive:Bool = false;
	public var onCollect:Void->Void; // Callback when orb is collected

	var floatTimer:Float = 0;
	var floatAmplitude:Float = 4;
	var floatFrequency:Float = 2;
	var moveTowardPlayerDelay:Float = 0.5; // Delay before orb starts moving toward player
	var moveDelay:Float = 0;
	var targetPlayer:Player;
	var ghostLevel:Int = 1; // How many levels to give the player when collected

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
		centerOffsets();

		antialiasing = false;
		isActive = false;
		exists = false;
		alpha = 0;
		
	}

	public function spawn(X:Float, Y:Float, player:Player, level:Int = 1):Void
	{
		reset(x = X - width / 2, y = Y - height / 2);

		setupShadow("player"); // Spirit orbs use player shadow

		velocity.set();
		isActive = true;
		exists = true;
		visible = true;
		alpha = 0;
		floatTimer = 0;
		moveDelay = moveTowardPlayerDelay;
		targetPlayer = player;
		ghostLevel = level; // Store the ghost's level

		FlxTween.tween(this, {alpha: 0.9}, 0.3);
	}

	override public function kill()
	{
		super.kill(); // GameEntity handles shadow cleanup
		velocity.set();
		targetPlayer = null;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!alive)
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
			kill();
			return;
		}

		// Level up the player by the ghost's level (kill level 3 ghost = gain 3 levels)
		targetPlayer.levelUp(ghostLevel);
		
		if (onCollect != null)
			onCollect();

		kill();
	}
}
