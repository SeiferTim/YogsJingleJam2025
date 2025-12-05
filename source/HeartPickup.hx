package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class HeartPickup extends FlxSprite
{
	public var shadow:Shadow;

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
		if (shadow == null)
		{
			shadow = new Shadow(this, 0.8, 0.5, 0, height / 2);
			PlayState.current.shadowLayer.add(shadow);
		}
		else
		{
			shadow.revive();
		}
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
		}

		kill();
	}

	override function kill():Void
	{
		super.kill();
		FlxTween.cancelTweensOf(this);

		if (shadow != null)
		{
			shadow.kill();
		}
	}
}
