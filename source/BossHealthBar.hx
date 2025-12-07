package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;
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
	var nameLetters:Array<FlxSprite>; // Individual sprites for each letter
	var font:FlxBitmapFont;

	var boss:IBoss;
	var previousHealth:Float;
	var activeTween:FlxTween;
	var damageAccumulated:Float = 0;
	var damageTween:FlxTween;

	var barX:Float;
	var barY:Float;
	var barWidth:Int;
	var barHeight:Int;

	public function new(Boss:IBoss, X:Float, Y:Float, Width:Int, Height:Int)
	{
		super();

		boss = Boss;
		previousHealth = boss.maxHealth; // Use maxHealth, not currentHealth (which might be 0 during intro)
		activeTween = null;

		barX = X;
		barY = Y;
		barWidth = Width;
		barHeight = Height;

		// Load sml-font for boss name letters
		font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);
		nameLetters = [];

		damageBar = new FlxBar(barX, barY, LEFT_TO_RIGHT, Width, Height, null, "", 0, boss.maxHealth, true);
		damageBar.createFilledBar(FlxColor.fromRGB(40, 40, 40), FlxColor.WHITE, true, FlxColor.fromRGB(120, 120, 120), 1);
		damageBar.scrollFactor.set(0, 0);
		damageBar.value = boss.maxHealth;
		add(damageBar);

		healthBar = new FlxBar(barX, barY, LEFT_TO_RIGHT, Width, Height, boss, "currentHealth", 0, boss.maxHealth, true);
		healthBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED, true, FlxColor.fromRGB(120, 120, 120), 1);
		healthBar.scrollFactor.set(0, 0);
		add(healthBar);

		// Create boss name AFTER bars
		createBossName();

		// Create damage text - STARTS INVISIBLE
		damageText = new FlxBitmapText(font);
		damageText.text = "0";
		damageText.scrollFactor.set(0, 0);
		damageText.y = barY - 10; // Same Y as boss name
		damageText.alpha = 0; // Start invisible
		damageText.x = barX + barWidth - damageText.width;
		add(damageText);
	}

	function createBossName():Void
	{
		var name = boss.bossName;
		var nameY = barY - 10; // 10px above the bar
		var currentX = barX;

		// Create a sprite for each letter using the font's character frame data
		for (i in 0...name.length)
		{
			var charCode = name.charCodeAt(i);

			// Handle spaces - add extra spacing
			if (charCode == 32) // space character
			{
				currentX += 5;
				continue;
			}

			var frame = font.getCharFrame(charCode);

			if (frame != null)
			{
				// Create sprite and load the font graphic
				var letterSprite = new FlxSprite(currentX, nameY);
				letterSprite.loadGraphic(AssetPaths.sml_font__png);
				letterSprite.frame = frame;
				letterSprite.scrollFactor.set(0, 0);
				letterSprite.alpha = 0; // Start invisible

				nameLetters.push(letterSprite);
				add(letterSprite);

				// Use xadvance for proper spacing
				var charAdvance = font.getCharAdvance(charCode);
				currentX += charAdvance;
			}
		}
	}

	public function revealBossName(duration:Float = 1.0):Void
	{
		var letterDelay = 0.05; // Delay between each letter

		// Fade in each letter sprite with staggered timing
		for (i in 0...nameLetters.length)
		{
			var letter = nameLetters[i];
			FlxTween.tween(letter, {alpha: 1}, 0.2, {
				startDelay: i * letterDelay,
				ease: FlxEase.quadOut
			});
		}
	}

	public function showDamage(damage:Float):Void
	{
		damageAccumulated = damageText.alpha >= 0.33 ? damageAccumulated + damage : damage;
		damageText.text = Std.string(Math.round(damageAccumulated));
		damageText.x = barX + barWidth - damageText.width;

		if (damageTween != null)
			damageTween.cancel();

		damageText.alpha = 1.0;
		damageTween = FlxTween.tween(damageText, {alpha: 0}, 0.33, {startDelay: 0.5, ease: FlxEase.quadOut});
	}

	public function setAlpha(value:Float):Void
	{
		// Only set alpha on bars - letters and damage text manage their own alpha
		damageBar.alpha = value;
		healthBar.alpha = value;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (boss.currentHealth < previousHealth)
		{
			previousHealth = boss.currentHealth;

			if (activeTween != null)
				activeTween.cancel();

			activeTween = FlxTween.tween(damageBar, {value: boss.currentHealth}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.5});
		}
	}
}
