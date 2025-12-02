package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class HUD extends FlxGroup
{
	var weaponCooldownIcon:CooldownIcon;
	var dodgeCooldownIcon:CooldownIcon;
	var hearts:Array<FlxSprite>;
	var bossHealthBar:BossHealthBar;

	var player:Player;
	var boss:Boss;

	var padding:Int = 4;

	public function new(Player:Player, Boss:Boss)
	{
		super();
		player = Player;
		boss = Boss;

		// Hearts (with 0 spacing between them)
		hearts = [];
		for (i in 0...player.maxHP)
		{
			var heart = new FlxSprite(padding + i * 8, padding);
			heart.loadGraphic("assets/images/heart.png");
			heart.scrollFactor.set(0, 0);
			add(heart);
			hearts.push(heart);
		}

		// Cooldown icons below hearts, aligned with leftmost heart
		var iconsY = padding + 8 + 2; // Below hearts with 2px gap

		// Weapon cooldown icon
		weaponCooldownIcon = new CooldownIcon(padding, iconsY, "assets/images/bow-arrow-icon.png");
		add(weaponCooldownIcon);

		// Dodge cooldown icon (14px = 12px icon width + 2px gap)
		dodgeCooldownIcon = new CooldownIcon(padding + 14, iconsY, "assets/images/dodge-icon.png");
		add(dodgeCooldownIcon);

		var barWidth:Int = 180;
		var barHeight:Int = 3;
		var barX:Float = (FlxG.width - barWidth) / 2;
		var barY:Float = FlxG.height - barHeight - padding * 2;

		bossHealthBar = new BossHealthBar(boss, barX, barY, barWidth, barHeight);
		add(bossHealthBar);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		updateHearts();
		updateWeaponCooldown();
		updateDodgeCooldown();
	}

	function updateHearts():Void
	{
		for (i in 0...hearts.length)
		{
			hearts[i].visible = i < player.currentHP;
		}
	}

	function updateWeaponCooldown():Void
	{
		var cooldownPercent = player.weapon.cooldownTimer / (player.weapon.cooldown * player.attackCooldown);
		weaponCooldownIcon.updateCooldown(cooldownPercent);

		// Show charge state with full charge detection
		var chargePercent = player.weapon.getChargePercent();
		var isFullCharge = player.weapon.isCharging && chargePercent >= 1.0;
		weaponCooldownIcon.updateCharge(chargePercent, isFullCharge);
	}

	function updateDodgeCooldown():Void
	{
		var cooldownPercent = player.dodgeTimer / player.dodgeCooldown;
		dodgeCooldownIcon.updateCooldown(cooldownPercent);
	}
}
