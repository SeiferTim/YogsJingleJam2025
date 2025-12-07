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

	public function new()
	{
		super();
	}

	/**
	 * Helper to setup or revive shadow with given parameters.
	 * Call this in your spawn() method instead of duplicating shadow creation code.
	 * 
	 * @param scale Shadow scale (size relative to sprite)
	 * @param alpha Shadow transparency (0-1)
	 * @param offsetX X offset from sprite position
	 * @param offsetY Y offset from sprite position
	 */
	public function setupShadow(scale:Float = 1.0, alpha:Float = 0.5, offsetX:Float = 0, offsetY:Float = 0):Void
	{
		if (shadow == null)
		{
			shadow = new Shadow(this, scale, alpha, offsetX, offsetY);
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
	 */
	public function takeDamage(damage:Float):Void
	{
		currentHealth -= damage;
		if (currentHealth <= 0)
		{
			kill();
		}
	}

	/**
	 * Override kill to automatically handle shadow cleanup.
	 * Subclasses should call super.kill() to ensure shadows are cleaned up.
	 */
	override public function kill():Void
	{
		super.kill();

		if (shadow != null)
		{
			shadow.kill();
		}
	}
}
