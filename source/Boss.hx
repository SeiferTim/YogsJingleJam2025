package;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class Boss extends FlxSprite
{
	public var maxHealth:Float = 1000;
	public var currentHealth:Float = 1000;
	public var contactDamage:Float = 1.0;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);

		makeGraphic(32, 32, FlxColor.PURPLE);

		immovable = true;

		currentHealth = maxHealth;
	}

	public function takeDamage(damage:Float):Void
	{
		currentHealth -= damage;
		if (currentHealth < 0)
			currentHealth = 0;

		if (currentHealth <= 0)
		{
			die();
		}
	}

	function die():Void
	{
		kill();
	}
}
