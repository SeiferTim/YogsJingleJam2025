package;

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

	var titleText:FlxBitmapText;
	var font:FlxBitmapFont;

	override function create():Void
	{
		super.create();

		bgColor = 0xff1a1a2e;

		// Pixel-perfect rendering
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;

		// Load bitmap font
		font = FlxBitmapFont.fromAngelCode(AssetPaths.sml_font__png, AssetPaths.sml_font__xml);

		// Title at top of screen
		titleText = new FlxBitmapText(font);
		titleText.text = "CHOOSE YOUR CHAMPION";
		// titleText.letterSpacing = 1;
		titleText.x = Math.floor(FlxG.width / 2 - titleText.width / 2);
		titleText.y = 2;
		add(titleText);

		// Generate 6 random characters
		characters = generateRandomCharacters(6);

		// Create character cards - very compact for 144px screen
		characterCards = new FlxTypedGroup<CharacterCard>();
		add(characterCards);

		var cardWidth = 70;
		var cardHeight = 52; // Updated to match new card size
		var cardSpacing = 8; // Horizontal spacing between cards
		var cardsPerRow = 3;
		var rowSpacing = 6; // Vertical spacing between rows

		// Calculate positioning - leave room for title at top
		var totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1));
		var totalHeight = (cardHeight * 2) + rowSpacing; // 52 + 6 + 52 = 110px total
		var startX = Math.floor((FlxG.width - totalWidth) / 2);
		var startY = Math.floor((FlxG.height - totalHeight) / 2) + 2; // Shift down slightly for title

		for (i in 0...characters.length)
		{
			var row = Math.floor(i / cardsPerRow);
			var col = i % cardsPerRow;
			var cardX = startX + (col * (cardWidth + cardSpacing));
			var cardY = startY + (row * (cardHeight + rowSpacing));

			var card = new CharacterCard(cardX, cardY, characters[i], onCharacterSelected);
			characterCards.add(card);
		}
	}

	function generateRandomCharacters(count:Int):Array<CharacterData>
	{
		var result:Array<CharacterData> = [];

		for (i in 0...count)
		{
			result.push(CharacterData.createRandom());
		}

		return result;
	}

	function onCharacterSelected(character:CharacterData):Void
	{
		// Store selected character globally (we'll pass it to PlayState)
		FlxG.switchState(() -> new PlayState(character));
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
