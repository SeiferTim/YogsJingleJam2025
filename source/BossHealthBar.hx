package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class BossHealthBar extends FlxGroup
{
	var damageBar:FlxBar;
	var healthBar:FlxBar;
	var damageText:FlxBitmapText;

	var boss:IBoss;
	var previousHealth:Float;
	var activeTween:FlxTween;
	var damageTextTimer:Float = 0;
	var damageTextDuration:Float = 1.5;

	var barX:Float;
	var barY:Float;
	var barWidth:Int;

	public function new(Boss:IBoss, X:Float, Y:Float, Width:Int, Height:Int)
	{
		super();

		boss = Boss;
		previousHealth = boss.currentHealth;
		activeTween = null;

		barX = X;
		barY = Y;
		barWidth = Width;

		damageBar = new FlxBar(barX, barY, LEFT_TO_RIGHT, Width, 6, null, "", 0, boss.maxHealth, true);
		damageBar.createFilledBar(FlxColor.fromRGB(40, 40, 40), FlxColor.WHITE, true, FlxColor.fromRGB(120, 120, 120), 1);
		damageBar.scrollFactor.set(0, 0);
		damageBar.value = boss.maxHealth;
		add(damageBar);

		healthBar = new FlxBar(barX, barY, LEFT_TO_RIGHT, Width, 6, boss, "currentHealth", 0, boss.maxHealth, true);
		healthBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED, true, FlxColor.fromRGB(120, 120, 120), 1);
		healthBar.scrollFactor.set(0, 0);
		add(healthBar);

		damageText = new FlxBitmapText(GameNumberFont.loadFont());
		damageText.text = "";
		damageText.scrollFactor.set(0, 0);
		damageText.visible = false;
		add(damageText);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (boss.currentHealth < previousHealth)
		{
			if (previousHealth == boss.currentHealth)
				return;

			var damage = previousHealth - boss.currentHealth;
			showDamageNumber(damage);

			previousHealth = boss.currentHealth;
			if (activeTween != null)
			{
				activeTween.cancel();
			}
			activeTween = FlxTween.tween(damageBar, {value: boss.currentHealth}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.5});
		}

		if (damageText.visible)
		{
			damageTextTimer += elapsed;
			if (damageTextTimer >= damageTextDuration)
			{
				damageText.visible = false;
			}
		}
	}

	function showDamageNumber(damage:Float):Void
	{
		damageText.text = Std.string(Math.round(damage));
		damageText.x = barX + (barWidth - damageText.width) / 2;
		damageText.y = barY + (6 - damageText.height) / 2;
		damageText.visible = true;
		damageTextTimer = 0;
	}
}
