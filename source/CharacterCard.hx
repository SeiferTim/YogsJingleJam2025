package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

class CharacterCard extends FlxSpriteGroup
{
	var character:CharacterData;
	var onSelect:CharacterData->Void;

	var background:FlxSprite;
	var portrait:FlxSprite;
	var nameText:FlxBitmapText;
	var classText:FlxBitmapText;
	var weaponIcon:FlxSprite;
	var selectButton:PixelButton;
	var font:FlxBitmapFont;

	var cardWidth:Int = 70;
	var cardHeight:Int = 52; // Slightly bigger to accommodate proper button with bitmap font

	public function new(X:Float, Y:Float, character:CharacterData, onSelect:CharacterData->Void)
	{
		super(X, Y);

		this.character = character;
		this.onSelect = onSelect;

		// Load bitmap font with proper letter spacing
		font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);

		createCard();
	}

	function createCard():Void
	{
		// Background card
		background = new FlxSprite(0, 0);
		background.makeGraphic(cardWidth, cardHeight, 0xff2d3561);
		add(background);

		// Character name at top - centered
		nameText = new FlxBitmapText(font);
		nameText.text = character.name;
		// nameText.letterSpacing = 1;
		nameText.x = Math.floor((cardWidth - nameText.width) / 2);
		nameText.y = 1;
		add(nameText);

		// Portrait and weapon icon side-by-side - centered
		var portraitY = 13;
		portrait = new FlxSprite(Math.floor((cardWidth - 8 - 2 - 8) / 2), portraitY); // Center the pair
		portrait.loadGraphic(AssetPaths.players__png, true, 8, 8);
		portrait.animation.frameIndex = character.spriteFrame; // Use stored sprite frame
		portrait.antialiasing = false;
		add(portrait);

		weaponIcon = new FlxSprite(Math.floor((cardWidth - 8 - 2 - 8) / 2) + 8 + 2, portraitY); // 2px gap
		weaponIcon.loadGraphic("assets/images/weapon-type-icons.png", true, 8, 8);
		weaponIcon.animation.frameIndex = getWeaponIconFrame();
		weaponIcon.antialiasing = false;
		add(weaponIcon);

		// Stats as icons - moved up closer to portrait/weapon
		var statsY = 26; // Closer to portrait/weapon icons
		var iconSpacing = 14;
		var startX = Math.floor((cardWidth - (8 + iconSpacing + 8 + iconSpacing + 8)) / 2);

		// ATK icon
		createStatIcon(startX, statsY, 0, character.bestStat == DAMAGE, character.worstStat == DAMAGE);

		// SPD icon
		createStatIcon(startX + 8 + iconSpacing, statsY, 1, character.bestStat == SPEED, character.worstStat == SPEED);

		// CDN icon
		createStatIcon(startX + 16 + iconSpacing * 2, statsY, 2, character.bestStat == COOLDOWN, character.worstStat == COOLDOWN);

		// PICK button using custom PixelButton with bitmap font
		var buttonWidth = cardWidth - 8;
		var buttonHeight = 12;
		var buttonY = 39; // Room for proper button
		selectButton = new PixelButton(4, buttonY, buttonWidth, buttonHeight, "PICK", font, onSelectClicked);
		add(selectButton);
	}

	function getClassName():String
	{
		return switch (character.weaponType)
		{
			case BOW: "Archer";
			case SWORD: "Warrior";
			case WAND: "Mage";
			case HALBERD: "Halberd";
		}
	}

	function createStatIcon(X:Float, Y:Float, iconType:Int, isBoosted:Bool, isWeakened:Bool):Void
	{
		// Create a small icon representing the stat type
		// iconType: 0=ATK, 1=SPD, 2=CDN
		var icon = new FlxSprite(X, Y);

		// Placeholder colors (different for each stat type)
		var iconColor = switch (iconType)
		{
			case 0: 0xffff4444; // Red for ATK
			case 1: 0xff44ff44; // Green for SPD
			case 2: 0xff4444ff; // Blue for CDN
			default: 0xff4a5a8a;
		}
		icon.makeGraphic(8, 8, iconColor);
		add(icon);

		// Modifier symbol centered OVER the icon (overlapping, not above)
		if (isBoosted || isWeakened)
		{
			var modifierText = new FlxBitmapText(font);
			modifierText.text = isBoosted ? "+" : "-";
			// modifierText.letterSpacing = 1;
			// Center horizontally AND vertically over the 8x8 icon
			modifierText.x = X + Math.floor((8 - modifierText.width) / 2);
			modifierText.y = Y + Math.floor((8 - modifierText.height) / 2);

			// Color the modifier
			if (isBoosted)
				modifierText.color = 0xff2ecc71; // Green
			else
				modifierText.color = 0xffe74c3c; // Red

			add(modifierText);
		}
	}

	function getWeaponSymbol():String
	{
		return switch (character.weaponType)
		{
			case BOW: "B";
			case SWORD: "S";
			case WAND: "M";
			case HALBERD: "H";
		}
	}

	function getWeaponIconFrame():Int
	{
		// Single sprite sheet with 4 frames: bow=0, sword=1, wand=2, halberd=3
		return switch (character.weaponType)
		{
			case BOW: 0;
			case SWORD: 1;
			case WAND: 2;
			case HALBERD: 3;
		}
	}

	function onSelectClicked():Void
	{
		if (onSelect != null)
			onSelect(character);
	}
}
