package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class HUD extends FlxGroup
{
	var weaponCooldownIcon:CooldownIcon;
	var dodgeCooldownIcon:CooldownIcon;
	var hearts:Array<FlxSprite>;
	public var bossHealthBar:BossHealthBar;
	var characterNameText:FlxBitmapText;

	var player:Player;
	var boss:IBoss;

	var padding:Int = 3; // Horizontal and vertical padding

	// Custom alpha management
	var _alpha:Float = 1.0;

	// Expose as a property so PlayState can assign `hud.alpha = value`.
	public var alpha(get, set):Float;

	public function setAlpha(value:Float):Void
	{
		_alpha = value;
		// Apply alpha to all members EXCEPT boss health bar (it manages its own alpha)
		forEach(function(member:FlxBasic)
		{
			if (member == bossHealthBar)
				return; // Skip boss health bar

			if (Std.isOfType(member, FlxSprite))
			{
				var sprite:FlxSprite = cast member;
				sprite.alpha = value;
			}
			else if (Std.isOfType(member, FlxGroup))
			{
				var group:FlxGroup = cast member;
				group.forEach(function(child:FlxBasic)
				{
					if (Std.isOfType(child, FlxSprite))
					{
						var sprite:FlxSprite = cast child;
						sprite.alpha = value;
					}
				});
			}
		});
	}

	function get_alpha():Float
	{
		return _alpha;
	}

	function set_alpha(value:Float):Float
	{
		setAlpha(value);
		return value;
	}

	public function new(Player:Player, Boss:IBoss, ?characterName:String)
	{
		super();
		player = Player;
		boss = Boss;

		var currentY = padding - 2; // Start 2px higher to account for font spacing

		// Character name at top left above hearts
		if (characterName != null && characterName.length > 0)
		{
			var font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);
			characterNameText = new FlxBitmapText(font);
			characterNameText.text = characterName;
			characterNameText.scrollFactor.set(0, 0);
			characterNameText.x = padding;
			characterNameText.y = currentY;
			add(characterNameText);

			currentY += Std.int(characterNameText.height) + 2; // Move down with 2px gap
		}

		// Hearts (with 0 spacing between them) - heart.png has 2 frames: 0=filled, 1=empty
		hearts = [];
		for (i in 0...player.maxHP)
		{
			var heart = new FlxSprite(padding + i * 8, currentY);
			heart.loadGraphic("assets/images/heart.png", true, 8, 8);
			heart.animation.add("full", [0]);
			heart.animation.add("empty", [1]);
			heart.animation.play("full");
			heart.scrollFactor.set(0, 0);
			add(heart);
			hearts.push(heart);
		}

		// Cooldown icons below hearts, aligned with leftmost heart
		var iconsY = currentY + 8 + 2; // Below hearts with 2px gap

		// Weapon cooldown icon - use single sprite with frame selection
		var weaponFrame = getWeaponIconFrame();
		weaponCooldownIcon = new CooldownIcon(padding, iconsY, "assets/images/weapon-type-icons.png", weaponFrame);
		add(weaponCooldownIcon);

		// Dodge cooldown icon (14px = 12px icon width + 2px gap)
		dodgeCooldownIcon = new CooldownIcon(padding + 14, iconsY, "assets/images/dodge-icon.png");
		add(dodgeCooldownIcon);

		var barWidth:Int = Std.int(FlxG.width - 16);
		var barHeight:Int = 3;
		var barX:Float = 8;
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
			// Show full heart if we have HP, empty heart if we don't
			hearts[i].animation.play(i < player.currentHP ? "full" : "empty");
		}
	}

	function updateWeaponCooldown():Void
	{
		var cooldownPercent = player.weapon.cooldownTimer / (player.weapon.cooldown / (1.0 + player.moveSpeed * 0.5));
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
	public function setBossHealthVisible(visible:Bool):Void
	{
		if (bossHealthBar != null)
			bossHealthBar.visible = visible;
	}
	public function revealBossName():Void
	{
		if (bossHealthBar != null)
			bossHealthBar.revealBossName();
	}

	function getWeaponIconFrame():Int
	{
		// Determine weapon frame from player's weapon type
		// Frame order: bow=0, sword=1, wand=2, halberd=3
		if (Std.isOfType(player.weapon, Arrow))
			return 0;
		else if (Std.isOfType(player.weapon, Sword))
			return 1;
		else if (Std.isOfType(player.weapon, Wand))
			return 2;
		else if (Std.isOfType(player.weapon, Halberd))
			return 3;
		else
			return 0; // Default to bow
	}
}
