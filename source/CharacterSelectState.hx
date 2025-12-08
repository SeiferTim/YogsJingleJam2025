package;

import CharacterData.WeaponType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class CharacterSelectState extends FlxState
{
	var characters:Array<CharacterData>;
	var characterCards:FlxTypedGroup<CharacterCard>;
	var nav:NavigableMenu;

	var titleText:FlxBitmapText;
	var font:FlxBitmapFont;
	public var ready:Bool = false;

	override function create():Void
	{
		super.create();

		Sound.playMusic("menu");

		bgColor = 0xff1a1a2e;
		FlxG.mouse.visible = false;

		// Pixel-perfect rendering
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;

		// Load bitmap font
		font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);

		// Calculate card positions first to position title in the gap
		var cardWidth = 70;
		var cardHeight = 60;
		var bottomRowY = FlxG.height - cardHeight - 1; // 1px from bottom
		var topRowY = bottomRowY - cardHeight - 1; // 1px above bottom row

		// Title centered in gap between top of screen and top of cards
		titleText = new FlxBitmapText(font);
		titleText.text = "CHOOSE YOUR CHAMPION";
		// titleText.letterSpacing = 1;
		titleText.x = Math.floor(FlxG.width / 2 - titleText.width / 2);
		// Center vertically in the gap: (0 + topRowY) / 2 - height/2
		titleText.y = Math.floor(topRowY / 2 - titleText.height / 2);
		add(titleText);

		// Generate 6 random characters
		characters = generateRandomCharacters(6);

		// Create character cards - very compact for 144px screen
		characterCards = new FlxTypedGroup<CharacterCard>();
		add(characterCards);

		var cardSpacing = 8; // Horizontal spacing between cards
		var cardsPerRow = 3;
		// Position cards (card dimensions already calculated above)
		// var bottomRowY and topRowY already set

		// Calculate horizontal positioning
		var totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1));
		var startX = Math.floor((FlxG.width - totalWidth) / 2);

		for (i in 0...characters.length)
		{
			var row = Math.floor(i / cardsPerRow);
			var col = i % cardsPerRow;
			var cardX = startX + (col * (cardWidth + cardSpacing));
			var cardY = row == 0 ? topRowY : bottomRowY; // Top row or bottom row

			var card = new CharacterCard(cardX, cardY, characters[i], onCharacterSelected);
			characterCards.add(card);
		}
		// Collect all card buttons for navigation
		var buttons:Array<FlxButton> = [];
		for (card in characterCards)
		{
			buttons.push(cast card.selectButton);
		}

		// Create navigation system
		nav = new NavigableMenu(buttons, GameGlobals.mouseHandler);
		nav.enabled = false;

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true, () ->
		{
			FlxG.mouse.visible = true;
			ready = true;
			nav.enabled = true;
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (ready && nav != null)
		{
			nav.update(elapsed);
		}
	}

	function generateRandomCharacters(count:Int):Array<CharacterData>
	{
		var result:Array<CharacterData> = [];

		// Guarantee one of each weapon type appears
		var guaranteedWeapons = [WeaponType.BOW, WeaponType.SWORD, WeaponType.WAND];
		var allWeapons = [WeaponType.BOW, WeaponType.SWORD, WeaponType.WAND];

		// First 3 characters: one of each weapon type
		for (i in 0...3)
		{
			var char = CharacterData.createRandom();
			// Override the weapon to guarantee one of each type
			char.weaponType = guaranteedWeapons[i];

			// Update sprite frame to match weapon
			var isFemale = char.spriteFrame >= 4;
			var frameOffset = isFemale ? 4 : 0;
			char.spriteFrame = switch (char.weaponType)
			{
				case BOW: 0 + frameOffset;
				case SWORD: 1 + frameOffset;
				case WAND: 2 + frameOffset;
				default: 0 + frameOffset;
			}

			result.push(char);
		}

		// Remaining characters: completely random
		for (i in 3...count)
		{
			result.push(CharacterData.createRandom());
		}
		// Shuffle the array so guaranteed weapons aren't always in same positions
		for (i in 0...result.length)
		{
			var j = Std.random(result.length);
			var temp = result[i];
			result[i] = result[j];
			result[j] = temp;
		}

		return result;
	}

	function onCharacterSelected(character:CharacterData):Void
	{
		// Store selected character globally (we'll pass it to PlayState)
		if (!ready)
			return;
		ready = false;
		Sound.stopMusic();
		axollib.AxolAPI.sendEvent("CHARACTER_SELECTED");
		FlxG.camera.fade(FlxColor.BLACK, 0.5, false, () ->
		{
			FlxG.switchState(() -> new PlayState(character));
		});
	}
}
