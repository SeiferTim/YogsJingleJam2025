package;

import CharacterData.WeaponType;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * Base class for all game entities that have shadows and health.
 * Eliminates duplicate shadow management, weapon creation, and damage handling code.
 */
class GameEntity extends FlxSprite
{
	public var shadow:Shadow;
	public var currentHealth:Float = 1;
	public var weapon:Weapon;

	// Damage cooldown tracking (prevents rapid damage from same projectile instance)
	public var damageTracker:DamageTracker = new DamageTracker(1000); // 1 second cooldown

	public function new()
	{
		super();
		// Create shadow in constructor (child class specifies type later via setupShadow)
	}

	/**
	 * Helper to setup shadow with given type and parameters.
	 * Call this in your spawn() method.
	 * 
	 * @param type Shadow type: "player", "bug", or "bossSegment"
	 * @param offsetX X offset from sprite center (default 0)
	 * @param offsetY Y offset from sprite center (default based on type)
	 */
	public function setupShadow(type:String, ?offsetX:Float = 0, ?offsetY:Float = null):Void
	{
		if (shadow == null)
		{
			shadow = new Shadow(this, type, offsetX, offsetY);
			PlayState.current.shadowLayer.add(shadow);
		}
		else
		{
			shadow.revive();
		}
	}

	/**
	 * Factory method to create weapon instances based on weapon type.
	 * Eliminates duplicate weapon creation switches in Player and Ghost.
	 * 
	 * @param weaponType The type of weapon to create
	 * @param projectiles The projectile group to use
	 * @return The created weapon instance
	 */
	public function createWeapon(weaponType:WeaponType, projectiles:FlxTypedGroup<Projectile>):Weapon
	{
		return switch (weaponType)
		{
			case BOW: new Arrow(this, projectiles);
			case SWORD: new Sword(this, projectiles);
			case WAND: new Wand(this, projectiles);
			case HALBERD: new Halberd(this, projectiles);
		}
	}

	/**
	 * Base damage handling. Reduces health and triggers death at 0.
	 * Override this to add flash effects or other damage feedback.
	 * 
	 * @param damage Amount of damage to take
	 * @param damageInstanceId Unique ID for damage source (for cooldown tracking)
	 */
	public function takeDamage(damage:Float, ?damageInstanceId:String):Void
	{
		// Check cooldown using DamageTracker
		if (!damageTracker.canTakeDamageFrom(damageInstanceId))
		{
			return; // Still on cooldown for this specific instance
		}
		
		currentHealth -= damage;
		// Record hit AFTER applying damage
		damageTracker.recordHit(damageInstanceId);
		
		if (currentHealth <= 0)
		{
			kill();
		}
	}

	/**
	 * Update damage tracker cooldowns.
	 * Subclasses should call super.update(elapsed) to ensure cooldowns are cleaned up.
	 */
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		damageTracker.update();
	}

	/**
	 * Override kill to automatically handle shadow cleanup and cooldown reset.
	 * Subclasses should call super.kill() to ensure shadows are cleaned up.
	 */
	override public function kill():Void
	{
		super.kill();
		damageTracker.reset(); // Clear cooldowns when killed/recycled

		if (shadow != null)
		{
			shadow.kill();
		}
	}
}
