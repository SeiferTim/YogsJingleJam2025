package;

import flixel.FlxSprite;

/**
 * Manages instance-based damage cooldown tracking for enemies.
 * 
 * Handles the problem where:
 * - Multiple projectiles of same type need separate cooldowns
 * - Recycled projectiles need new IDs per spawn
 * 
 * Each enemy class should have:
 *   var damageTracker:DamageTracker = new DamageTracker();
 * 
 * Then in takeDamage():
 *   if (!damageTracker.canTakeDamageFrom(damageInstanceId)) return;
 *   damageTracker.recordHit(damageInstanceId);
 * 
 * And in update():
 *   damageTracker.update();
 */
class DamageTracker
{
	// Maps damage instance ID to timestamp of last hit
	var lastHitByInstanceId:Map<String, Float> = new Map();

	// How long to wait between hits from same instance (in milliseconds)
	public var cooldownDuration:Float = 1000; // 1 second default

	public function new(cooldownDuration:Float = 1000)
	{
		this.cooldownDuration = cooldownDuration;
	}

	/**
	 * Check if this enemy can take damage from the given instance ID.
	 * @param damageInstanceId Unique ID for the damage source (null = always allow)
	 * @return True if damage should be applied
	 */
	public function canTakeDamageFrom(damageInstanceId:String):Bool
	{
		if (damageInstanceId == null)
			return true; // No cooldown tracking

		var currentTime = Date.now().getTime();
		var lastHitTime = lastHitByInstanceId.get(damageInstanceId);

		if (lastHitTime != null && currentTime - lastHitTime < cooldownDuration)
			return false; // Still on cooldown

		return true;
	}

	/**
	 * Record that this enemy was hit by the given instance.
	 * Call this AFTER applying damage.
	 * @param damageInstanceId Unique ID for the damage source
	 */
	public function recordHit(damageInstanceId:String):Void
	{
		if (damageInstanceId == null)
			return;

		var currentTime = Date.now().getTime();
		lastHitByInstanceId.set(damageInstanceId, currentTime);
	}

	/**
	 * Clean up old cooldown entries.
	 * Call this in your enemy's update() method.
	 */
	public function update():Void
	{
		var currentTime = Date.now().getTime();
		var idsToRemove = new Array<String>();

		for (instanceId in lastHitByInstanceId.keys())
		{
			var lastHitTime = lastHitByInstanceId.get(instanceId);
			if (lastHitTime != null && currentTime - lastHitTime >= cooldownDuration)
			{
				idsToRemove.push(instanceId);
			}
		}

		for (instanceId in idsToRemove)
		{
			lastHitByInstanceId.remove(instanceId);
		}
	}

	/**
	 * Clear all cooldown tracking.
	 * Call this when the enemy is killed/recycled.
	 */
	public function reset():Void
	{
		lastHitByInstanceId.clear();
	}
}
