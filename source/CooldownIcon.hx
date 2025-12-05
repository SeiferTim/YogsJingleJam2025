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

	public function new(X:Float, Y:Float, IconPath:String, ?frameIndex:Int = 0)
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
		icon.loadGraphic(IconPath, true, 8, 8);
		icon.animation.frameIndex = frameIndex;
		icon.antialiasing = false;
		icon.scrollFactor.set(0, 0);
		add(icon);

		scrollFactor.set(0, 0);
	}

	public function updateCooldown(cooldownPercent:Float):Void
	{
		var onCooldown = cooldownPercent > 0;
		cooldownBar.value = onCooldown ? cooldownPercent * 100 : 0;

		if (onCooldown != isOnCooldown)
		{
			isOnCooldown = onCooldown;
			var borderColor = onCooldown ? FlxColor.RED : FlxColor.fromRGB(120, 120, 120);
			cooldownBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED, true, borderColor);
		}
	}

	public function updateCharge(chargePercent:Float, isFullCharge:Bool):Void
	{
		chargeBar.value = chargePercent * 100;
		icon.offset.y = (chargePercent > 0 && isFullCharge) ? Math.sin(FlxG.game.ticks * 0.5) * 0.75 : 0;
	}
}
