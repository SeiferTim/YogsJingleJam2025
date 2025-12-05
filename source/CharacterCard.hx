package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxButton.FlxTypedButton;
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
	var selectButton:FlxTypedButton<FlxBitmapText>;
	var font:FlxBitmapFont;

	var cardWidth:Int = 70;
	var cardHeight:Int = 54; // +2px for spacing below button

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
		background.loadGraphic("assets/images/character-card-bg.png");
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

		// LCK icon
		createStatIcon(startX + 16 + iconSpacing * 2, statsY, 2, character.bestStat == LUCK, character.worstStat == LUCK);

		// PICK button using FlxTypedButton with bitmap font
		var buttonWidth = cardWidth - 8;
		var buttonHeight = 12;
		var buttonY = 39;

		selectButton = new FlxTypedButton<FlxBitmapText>(4, buttonY, onSelectClicked);
		selectButton.loadGraphic("assets/images/button-pick.png", true, buttonWidth, buttonHeight);
		selectButton.label = new FlxBitmapText(font);
		selectButton.label.text = "PICK";
		selectButton.label.color = FlxColor.WHITE;
		// Center label on button (label position is relative to button, not absolute)
		selectButton.label.offset.x = -Math.floor((buttonWidth - selectButton.label.width) / 2);
		selectButton.label.offset.y = -Math.floor((buttonHeight - selectButton.label.height) / 2);
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
		// Create colored background square
		var iconBg = new FlxSprite(X, Y);
		var bgColor = switch (iconType)
		{
			case 0: 0xffff4444; // Red for Power
			case 1: 0xffcc8800; // Orange for Agility (darker than yellow for better contrast)
			case 2: 0xff44ff44; // Green for Luck
			default: 0xff4a5a8a;
		}
		iconBg.makeGraphic(8, 8, bgColor);
		add(iconBg);

		// Create white letter on top
		// iconType: 0=ATK (P=Power), 1=SPD (A=Agility), 2=LCK (L=Luck)
		var statLetter = switch (iconType)
		{
			case 0: "P"; // Power (ATK)
			case 1: "A"; // Agility (SPD)
			case 2: "L"; // Luck (LCK)
			default: "?";
		}
		var statText = new FlxBitmapText(font);
		statText.text = statLetter;
		statText.color = 0xffffffff; // White letter
		// Center the letter on the 8x8 background
		statText.x = X + Math.floor((8 - statText.width) / 2);
		statText.y = Y + Math.floor((8 - statText.height) / 2);
		add(statText);

		// Modifier sprite (up/down arrow) at bottom-right corner of background
		// Must be added LAST to be visible on top
		if (isBoosted || isWeakened)
		{
			var modifierSprite = new FlxSprite(X + 8 - 3, Y + 8 - 3); // Position at bottom-right corner
			modifierSprite.loadGraphic("assets/images/up-down.png", true, 3, 3); // 2 frames: 0=UP, 1=DOWN
			modifierSprite.antialiasing = false; // Ensure pixel-perfect rendering
			
			if (isBoosted)
			{
				modifierSprite.animation.frameIndex = 0; // UP frame
			}
			else if (isWeakened)
			{
				modifierSprite.animation.frameIndex = 1; // DOWN frame
			}
			
			add(modifierSprite);
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
