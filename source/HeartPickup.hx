package;

import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class HeartPickup extends GameEntity
{

	var healAmount:Int = 1;

	public function new()
	{
		super();
		loadGraphic("assets/images/heart.png", true, 8, 8);
		animation.add("pulse", [0, 1], 4, true);
		animation.play("pulse");
		kill();
	}

	public function spawn(Pos:FlxPoint):Void
	{
		reset(Pos.x - 4, Pos.y - 4);
		setupShadow("player"); // Hearts use player shadow
		
		alpha = 0;
		offset.y = 4;
		FlxTween.tween(this, {alpha: 1}, 0.2, {
			onComplete: (_) ->
			{
				FlxTween.tween(offset, {y: 0}, 0.33, {ease: FlxEase.bounceOut});
			}
		});
	}

	public function collect(player:Player):Void
	{
		if (player.currentHP < player.maxHP)
		{
			player.currentHP = Std.int(Math.min(player.currentHP + healAmount, player.maxHP));
			Sound.playSound("player_heal");
			
		}

		kill();
	}

	override function kill():Void
	{
		FlxTween.cancelTweensOf(this);
		super.kill(); // Handles shadow cleanup automatically
	}
}
