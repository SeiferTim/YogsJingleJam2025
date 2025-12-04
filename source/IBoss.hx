package;

interface IBoss
{
	public var maxHealth:Float;
	public var currentHealth:Float;
	
	public function takeDamage(damage:Float):Void;
	public function die():Void;
	public function moveTo(x:Float, y:Float, speed:Float, elapsed:Float):Void;
}
