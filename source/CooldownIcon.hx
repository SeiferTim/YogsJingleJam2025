package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

class CooldownIcon extends FlxSpriteGroup
{
	var background:FlxSprite;
	var icon:FlxSprite;
	var cooldownBar:FlxBar;
	var chargeBar:FlxBar;

	var isOnCooldown:Bool = false;
	var baseIconY:Float = 2;

	public function new(X:Float, Y:Float, IconPath:String)
	{
		super(X, Y);

		background = new FlxSprite(0, 0);
		background.makeGraphic(12, 12, FlxColor.fromRGB(40, 40, 40));
		background.scrollFactor.set(0, 0);
		add(background);

		cooldownBar = new FlxBar(0, 0, BOTTOM_TO_TOP, 12, 12, null, "", 0, 100);
		cooldownBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED, true, FlxColor.fromRGB(120, 120, 120));
		cooldownBar.scrollFactor.set(0, 0);
		cooldownBar.value = 0;
		add(cooldownBar);

		chargeBar = new FlxBar(0, 0, BOTTOM_TO_TOP, 12, 12, null, "", 0, 100);
		chargeBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.YELLOW, false);
		chargeBar.scrollFactor.set(0, 0);
		chargeBar.value = 0;
		add(chargeBar);

		icon = new FlxSprite(2, 2);
		icon.loadGraphic(IconPath);
		icon.scrollFactor.set(0, 0);
		add(icon);

		scrollFactor.set(0, 0);
	}

	public function updateCooldown(cooldownPercent:Float):Void
	{
		if (cooldownPercent > 0)
		{
			cooldownBar.value = cooldownPercent * 100;

			if (!isOnCooldown)
			{
				isOnCooldown = true;
				cooldownBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED, true, FlxColor.RED);
			}
		}
		else
		{
			cooldownBar.value = 0;

			if (isOnCooldown)
			{
				isOnCooldown = false;
				cooldownBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED, true, FlxColor.fromRGB(120, 120, 120));
			}
		}
	}

	public function updateCharge(chargePercent:Float, isFullCharge:Bool):Void
	{
		if (chargePercent > 0)
		{
			chargeBar.value = chargePercent * 100;

			if (isFullCharge)
			{
				var shakeAmount = Math.sin(FlxG.game.ticks * 0.5) * 0.75;
				icon.offset.y = shakeAmount;
			}
			else
			{
				icon.offset.y = 0;
			}
		}
		else
		{
			chargeBar.value = 0;
			icon.offset.y = 0;
		}
	}
}
