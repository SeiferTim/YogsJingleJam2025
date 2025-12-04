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

	// Which stats are buffed/nerfed
	public var bestStat:StatType;
	public var worstStat:StatType;

	// Current progression
	public var level:Int;
	public var xp:Int;
	public var maxHP:Int;

	// Final calculated stats (with modifiers and level bonuses)
	// These match Player.hx stats
	public var attackDamage:Float;
	public var moveSpeed:Float;
	public var attackCooldown:Float;

	// XP curve: level * 100 XP needed for next level
	public static inline var XP_PER_LEVEL:Int = 100;

	// Leveling bonuses
	public static inline var STAT_INCREASE_PER_LEVEL:Float = 0.10; // 10% per level
	public static inline var HEALTH_EVERY_N_LEVELS:Int = 3; // +1 max heart every 3 levels

	// Best/Worst stat modifiers
	public static inline var BEST_STAT_BONUS:Float = 0.20; // +20%
	public static inline var WORST_STAT_PENALTY:Float = 0.20; // -20%

	// Base stat values
	public static inline var BASE_DAMAGE:Float = 1.0;
	public static inline var BASE_SPEED:Float = 1.0;
	public static inline var BASE_COOLDOWN:Float = 1.0;
	public static inline var BASE_HP:Int = 3; // 3 hearts to start

	public function new(Name:String, Weapon:WeaponType, BestStat:StatType, WorstStat:StatType)
	{
		name = Name;
		weaponType = Weapon;

		bestStat = BestStat;
		worstStat = WorstStat;

		level = 1;
		xp = 0;
		maxHP = BASE_HP;

		recalculateStats();
	}

	/**
	 * Add XP and check for level up.
	 * @return True if leveled up
	 */
	public function addXP(amount:Int):Bool
	{
		xp += amount;
		var xpNeeded = getXPForNextLevel();

		if (xp >= xpNeeded)
		{
			xp -= xpNeeded;
			level++;
			recalculateStats();
			return true; // Leveled up!
		}

		return false;
	}

	public function getXPForNextLevel():Int
	{
		return level * XP_PER_LEVEL;
	}

	public function recalculateStats():Void
	{
		// Start with base stats
		attackDamage = BASE_DAMAGE;
		moveSpeed = BASE_SPEED;
		attackCooldown = BASE_COOLDOWN;

		// Apply best/worst stat modifiers
		attackDamage = applyStatModifier(attackDamage, StatType.DAMAGE);
		moveSpeed = applyStatModifier(moveSpeed, StatType.SPEED);
		attackCooldown = applyStatModifier(attackCooldown, StatType.COOLDOWN);

		// Apply level bonuses (+10% per level after 1)
		var levelMultiplier = 1.0 + (level - 1) * STAT_INCREASE_PER_LEVEL;
		attackDamage *= levelMultiplier;
		moveSpeed *= levelMultiplier;
		// Note: Lower cooldown is better, so we DIVIDE instead of multiply for level bonus
		attackCooldown /= levelMultiplier;

		// Bonus hearts every N levels
		var bonusHearts = Math.floor((level - 1) / HEALTH_EVERY_N_LEVELS);
		maxHP = BASE_HP + bonusHearts;
	}

	private function applyStatModifier(value:Float, stat:StatType):Float
	{
		if (stat == bestStat)
			return value * (1.0 + BEST_STAT_BONUS);
		else if (stat == worstStat)
		{
			// For cooldown, worst means SLOWER (higher number)
			// For damage/speed, worst means LOWER (lower number)
			if (stat == StatType.COOLDOWN)
				return value * (1.0 + WORST_STAT_PENALTY); // Increases cooldown
			else
				return value * (1.0 - WORST_STAT_PENALTY); // Decreases damage/speed
		}
		return value;
	}

	/**
	 * Create a random character with random stats and weapon.
	 * Ensures best and worst stats are different.
	 */
	public static function createRandom():CharacterData
	{
		var names = [
			"Aldric",
			"Brom",
			"Cedric",
			"Doran",
			"Elara",
			"Finn",
			"Gwendolyn",
			"Hilda",
			"Isolde",
			"Jasper",
			"Keira",
			"Lorin",
			"Mira",
			"Nero",
			"Olwen",
			"Piers",
			"Quinn",
			"Rowan",
			"Sable",
			"Thorne",
			"Uma",
			"Vex",
			"Wren",
			"Xander",
			"Yara",
			"Zephyr"
		];

		var weapons = [WeaponType.BOW, WeaponType.SWORD, WeaponType.WAND];

		var name = names[Std.random(names.length)];
		var weapon = weapons[Std.random(weapons.length)];

		// Pick random best and worst stats (must be different)
		var allStats = [StatType.DAMAGE, StatType.SPEED, StatType.COOLDOWN];
		var bestStat = allStats[Std.random(allStats.length)];

		// Pick worst stat (different from best)
		var worstOptions = allStats.filter(s -> s != bestStat);
		var worstStat = worstOptions[Std.random(worstOptions.length)];

		return new CharacterData(name, weapon, bestStat, worstStat);
	}

	/**
	 * Serialize to simple object for saving
	 */
	public function toSaveData():Dynamic
	{
		return {
			name: name,
			weaponType: weaponType,
			bestStat: bestStat,
			worstStat: worstStat,
			level: level,
			xp: xp,
			maxHP: maxHP
		};
	}

	/**
	 * Deserialize from saved object
	 */
	public static function fromSaveData(data:Dynamic):CharacterData
	{
		var char = new CharacterData(data.name, data.weaponType, data.bestStat, data.worstStat);

		char.level = data.level;
		char.xp = data.xp;
		char.maxHP = data.maxHP;
		char.recalculateStats();

		return char;
	}

	/**
	 * Create a copy of this character (for ghost spawning)
	 */
	public function clone():CharacterData
	{
		var copy = new CharacterData(name, weaponType, bestStat, worstStat);
		copy.level = level;
		copy.xp = xp;
		copy.maxHP = maxHP;
		copy.recalculateStats();
		return copy;
	}
}

enum WeaponType
{
	BOW;
	SWORD;
	WAND;
}

enum StatType
{
	DAMAGE;
	SPEED;
	COOLDOWN;
}
