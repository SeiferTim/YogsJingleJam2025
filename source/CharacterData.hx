package;

/**
 * Data container for player character stats.
 * Used for both the current player and saved ghosts.
 * 
 * Each character has randomized stats with one BEST (+20%) and one WORST (-20%).
 */
class CharacterData
{
	public var name:String;
	public var weaponType:WeaponType;
	public var spriteFrame:Int; // Which sprite frame to use (0-7 in players.png)

	// Which stats are buffed/nerfed
	public var bestStat:StatType;
	public var worstStat:StatType;

	// Current progression
	public var level:Int;
	public var maxHP:Int;

	// Final calculated stats (with modifiers and level bonuses)
	public var attackDamage:Float;
	public var moveSpeed:Float;
	public var luck:Float;

	// Which phase the character died in (0 = before Phase 1, 1 = Phase 1, 2 = Phase 2, etc.)
	public var deathPhase:Int;

	// Leveling bonuses
	public static inline var STAT_INCREASE_PER_LEVEL:Float = 0.10; // 10% per level
	public static inline var HEALTH_EVERY_N_LEVELS:Int = 3; // +1 max heart every 3 levels

	// Best/Worst stat modifiers
	public static inline var BEST_STAT_BONUS:Float = 0.20; // +20%
	public static inline var WORST_STAT_PENALTY:Float = 0.20; // -20%

	// Base stat values
	public static inline var BASE_DAMAGE:Float = 1.0;
	public static inline var BASE_SPEED:Float = 1.0;
	public static inline var BASE_LUCK:Float = 1.0;
	public static inline var BASE_HP:Int = 3; // 3 hearts to start

	public function new(Name:String, Weapon:WeaponType, BestStat:StatType, WorstStat:StatType, SpriteFrame:Int = 0)
	{
		name = Name;
		weaponType = Weapon;
		spriteFrame = SpriteFrame;

		bestStat = BestStat;
		worstStat = WorstStat;

		level = 1;
		maxHP = BASE_HP;
		deathPhase = 0; // Default to 0 (alive)

		recalculateStats();
	}

	public function recalculateStats():Void
	{
		// Start with base stats
		attackDamage = BASE_DAMAGE;
		moveSpeed = BASE_SPEED;
		luck = BASE_LUCK;

		// Apply best/worst stat modifiers
		attackDamage = applyStatModifier(attackDamage, StatType.DAMAGE);
		moveSpeed = applyStatModifier(moveSpeed, StatType.SPEED);
		luck = applyStatModifier(luck, StatType.LUCK);

		// Apply level bonuses (+10% per level after 1)
		var levelMultiplier = 1.0 + (level - 1) * STAT_INCREASE_PER_LEVEL;
		attackDamage *= levelMultiplier;
		moveSpeed *= levelMultiplier;
		luck *= levelMultiplier;

		// Bonus hearts every N levels
		var bonusHearts = Math.floor((level - 1) / HEALTH_EVERY_N_LEVELS);
		maxHP = BASE_HP + bonusHearts;
	}

	private function applyStatModifier(value:Float, stat:StatType):Float
	{
		if (stat == bestStat)
			return value * (1.0 + BEST_STAT_BONUS);
		else if (stat == worstStat)
			return value * (1.0 - WORST_STAT_PENALTY);
		return value;
	}

	/**
	 * Create a random character with random stats and weapon.
	 * Ensures best and worst stats are different.
	 */
	public static function createRandom():CharacterData
	{
		var weapons = [WeaponType.BOW, WeaponType.SWORD, WeaponType.WAND];

		// First, pick gender and get a matching name
		// 50/50 chance for male or female (neutral names can match either)
		var isFemale = Math.random() > 0.5;
		var gender = isFemale ? "F" : "M";

		// Get name matching gender (Yogscast names have 3x higher chance)
		var nameEntry = NameData.getRandomName(gender, 3.0);
		var name = nameEntry.first_name;

		// Keep trying until we get a unique name not used by dead characters
		var deadCharacters = GameData.getDeadCharacters();
		var usedNames = [for (char in deadCharacters) char.name];

		// Failsafe: If we've used most names (>total-12), allow reusing names
		var totalAvailableNames = NameData.allNames.length;
		var shouldEnforceUnique = usedNames.length < (totalAvailableNames - 12);
		
		if (shouldEnforceUnique)
		{
			// Try to find unique name
			var attempts = 0;
			while (usedNames.contains(name) && attempts < 50)
			{
				nameEntry = NameData.getRandomName(gender, 3.0);
				name = nameEntry.first_name;
				attempts++;
			}
			
			// If still not unique after 50 tries, add a number suffix
			if (usedNames.contains(name))
			{
				var suffix = 2;
				while (usedNames.contains(name + " " + suffix))
					suffix++;
				name = name + " " + suffix;
			}
		}
		// else: Allow duplicate names - player has killed so many characters!
	
		var weapon = weapons[Std.random(weapons.length)]; // Pick random best and worst stats (must be different)
		var allStats = [StatType.DAMAGE, StatType.SPEED, StatType.LUCK];
		var bestStat = allStats[Std.random(allStats.length)];

		// Pick worst stat (different from best)
		var worstOptions = allStats.filter(s -> s != bestStat);
		var worstStat = worstOptions[Std.random(worstOptions.length)];

		// Generate sprite frame based on gender from name data
		var frameOffset = NameData.getFrameOffsetForGender(nameEntry.gender);

		var spriteFrame = switch (weapon)
		{
			case BOW: 0 + frameOffset; // archer
			case SWORD: 1 + frameOffset; // warrior
			case WAND: 2 + frameOffset; // mage
			default: 0 + frameOffset; // fallback to archer
		}

		return new CharacterData(name, weapon, bestStat, worstStat, spriteFrame);
	}

	/**
	 * Serialize to simple object for saving
	 */
	public function toSaveData():Dynamic
	{
		return {
			name: name,
			weaponType: weaponType,
			spriteFrame: spriteFrame,
			bestStat: bestStat,
			worstStat: worstStat,
			level: level,
			maxHP: maxHP,
			deathPhase: deathPhase
		};
	}

	/**
	 * Deserialize from saved object
	 */
	public static function fromSaveData(data:Dynamic):CharacterData
	{
		var char = new CharacterData(data.name, data.weaponType, data.bestStat, data.worstStat, data.spriteFrame);

		char.level = data.level;
		char.maxHP = data.maxHP;
		char.deathPhase = data.deathPhase != null ? data.deathPhase : 0;
		char.recalculateStats();

		return char;
	}

	/**
	 * Create a copy of this character (for ghost spawning)
	 */
	public function clone():CharacterData
	{
		var copy = new CharacterData(name, weaponType, bestStat, worstStat, spriteFrame);
		copy.level = level;
		copy.maxHP = maxHP;
		copy.deathPhase = deathPhase;
		copy.recalculateStats();
		return copy;
	}
}

enum WeaponType
{
	BOW;
	SWORD;
	WAND;
	HALBERD;
}

enum StatType
{
	DAMAGE;
	SPEED;
	LUCK;
}
