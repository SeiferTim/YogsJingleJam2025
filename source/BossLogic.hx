package;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * Shared boss logic helper class.
 * Handles common functionality for all boss phases:
 * - Health management
 * - Damage cooldown tracking
 * - Movement helpers
 * - Death detection
 * 
 * Usage: Each boss creates a BossLogic instance and delegates to it.
 */
class BossLogic
{
	public var maxHealth:Float;
	public var currentHealth:Float;
	public var damageTracker:DamageTracker;

	public function new(maxHealth:Float, cooldownDuration:Float = 1000)
	{
		this.maxHealth = maxHealth;
		this.currentHealth = maxHealth;
		this.damageTracker = new DamageTracker(cooldownDuration);
	}

	/**
	 * Update damage cooldown tracking.
	 * Call this in the boss's update() method.
	 */
	public function update():Void
	{
		damageTracker.update();
	}

	/**
	 * Check if this boss can take damage from the given instance ID.
	 * Returns false if still on cooldown.
	 * 
	 * @param damageInstanceId Unique ID for the damage source (null = always allow)
	 * @return True if damage should be applied
	 */
	public function canTakeDamage(damageInstanceId:String):Bool
	{
		return damageTracker.canTakeDamageFrom(damageInstanceId);
	}

	/**
	 * Apply damage to the boss.
	 * Handles health reduction and cooldown tracking.
	 * Does NOT handle visual effects - that's boss-specific.
	 * 
	 * @param damage Amount of damage to apply
	 * @param damageInstanceId Unique ID for damage tracking
	 * @return True if damage was applied (not on cooldown), false if blocked
	 */
	public function takeDamage(damage:Float, damageInstanceId:String):Bool
	{
		if (!canTakeDamage(damageInstanceId))
			return false;

		currentHealth -= damage;
		if (currentHealth < 0)
			currentHealth = 0;

		damageTracker.recordHit(damageInstanceId);
		return true;
	}

	/**
	 * Check if the boss is dead.
	 */
	public function isDead():Bool
	{
		return currentHealth <= 0;
	}

	/**
	 * Helper function to move towards a target position.
	 * Updates x/y directly - caller should apply to their sprite/position.
	 * 
	 * @param currentX Current X position
	 * @param currentY Current Y position
	 * @param targetX Target X position
	 * @param targetY Target Y position
	 * @param speed Movement speed
	 * @param elapsed Delta time
	 * @return Object with newX and newY positions
	 */
	public function moveTowards(currentX:Float, currentY:Float, targetX:Float, targetY:Float, speed:Float, elapsed:Float):{newX:Float, newY:Float}
	{
		var dx = targetX - currentX;
		var dy = targetY - currentY;
		var distance = Math.sqrt(dx * dx + dy * dy);

		if (distance < 1)
		{
			return {newX: targetX, newY: targetY};
		}

		var moveDistance = speed * elapsed;
		if (moveDistance > distance)
			moveDistance = distance;

		var newX = currentX + (dx / distance) * moveDistance;
		var newY = currentY + (dy / distance) * moveDistance;

		return {newX: newX, newY: newY};
	}

	/**
	 * Reset boss state (for recycling/respawn).
	 */
	public function reset():Void
	{
		currentHealth = maxHealth;
		damageTracker.reset();
	}
}
