package;

import flixel.FlxSprite;

interface IBoss
{
	public var maxHealth:Float;
	public var currentHealth:Float;
	public var bossName:String;
	
	public function takeDamage(damage:Float, ?damageInstanceId:String):Void;
	public function die():Void;
	public function moveTo(x:Float, y:Float, speed:Float, elapsed:Float):Void;
	/**
	 * Check if a sprite overlaps with any segment of this boss.
	 * @param sprite The sprite to check collision with
	 * @param useRotatedCollision If true, uses RotatedSprite's collision detection
	 * @param usePixelPerfect If true, uses pixel-perfect collision after basic overlap
	 * @return True if any segment overlaps with the sprite
	 */
	public function checkOverlap(sprite:FlxSprite, useRotatedCollision:Bool = false, usePixelPerfect:Bool = false):Bool;
}
