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
	public var selectButton:FlxTypedButton<FlxBitmapText>; // Public for navigation
	var font:FlxBitmapFont;

	var cardWidth:Int = 70;
	var cardHeight:Int = 60; // Reduced from 68: moved stats up 4px, button up 8px total = 8px shorter

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

		// Show only best and worst stats (text + up/down icon)
		var statsY = 22; // Same Y position as icons were
		var lineHeight = 8; // Font height

		// Find which stats to show
		var statLines:Array<{name:String, isUp:Bool}> = [];
		
		if (character.bestStat == DAMAGE)
			statLines.push({name: "POWER", isUp: true});
		else if (character.worstStat == DAMAGE)
			statLines.push({name: "POWER", isUp: false});
			
		if (character.bestStat == SPEED)
			statLines.push({name: "AGILITY", isUp: true});
		else if (character.worstStat == SPEED)
			statLines.push({name: "AGILITY", isUp: false});
			
		if (character.bestStat == LUCK)
			statLines.push({name: "LUCK", isUp: true});
		else if (character.worstStat == LUCK)
			statLines.push({name: "LUCK", isUp: false});

		// Show up to 2 stat lines (best and worst)
		for (i in 0...statLines.length)
		{
			if (i >= 2)
				break; // Max 2 lines
			createStatLine(statsY + lineHeight * i, statLines[i].name, statLines[i].isUp);
		}

		// PICK button - back to original position
		var buttonWidth = cardWidth - 8;
		var buttonHeight = 12;
		var buttonY = 43; // Original position

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

	function createStatLine(Y:Float, statName:String, isUp:Bool):Void
	{
		// Calculate total width: text + 2px gap + 8px arrow = text.width + 10
		// We want to center this combined width, treating text as if it's 8px wider
		var tempText = new FlxBitmapText(font);
		tempText.text = statName;
		var textWidth = tempText.width;

		// Total width to center: text + 8px (for visual balance as requested)
		var totalWidth = textWidth + 8;
		var startX = Math.floor((cardWidth - totalWidth) / 2);
		
		// Create text label for stat
		var statText = new FlxBitmapText(font);
		statText.text = statName;
		statText.x = startX; // Position text at start
		statText.y = Y;
		statText.color = FlxColor.WHITE;
		add(statText);

		// Add up/down arrow sprite - positioned relative to the GROUP, not the text sprite
		var arrowSprite = new FlxSprite(startX + textWidth + 2, Y); // 2px gap after text
		arrowSprite.loadGraphic("assets/images/up-down.png", true, 8, 8); // 2 frames: 0=UP, 1=DOWN
		arrowSprite.antialiasing = false;
		arrowSprite.animation.frameIndex = isUp ? 0 : 1; // 0=UP, 1=DOWN
		add(arrowSprite);
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
