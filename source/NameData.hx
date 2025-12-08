package;

typedef NameEntry =
{
	var first_name:String;
	var gender:String; // "M", "F", or "?"
	var yog:Bool;
}

/**
 * Name database with compile-time embedded data.
 * Uses @:build macro to embed names.json at compile time.
 */
@:build(macros.NameBuilder.build())
class NameData
{
	// allNames is added by the macro at compile time
	// public static var allNames:Array<NameEntry>;
	public static var maleNames:Array<NameEntry> = [];
	public static var femaleNames:Array<NameEntry> = [];
	public static var neutralNames:Array<NameEntry> = [];
	public static var yogNames:Array<NameEntry> = [];

	private static var initialized:Bool = false;

	/**
	 * Initialize the categorized name arrays.
	 * Call this once at game start.
	 */
	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;

		// Clear arrays
		maleNames = [];
		femaleNames = [];
		neutralNames = [];
		yogNames = [];

		// Categorize names (allNames is populated by macro)
		for (name in allNames)
		{
			switch (name.gender)
			{
				case "M":
					maleNames.push(name);
				case "F":
					femaleNames.push(name);
				case "?":
					neutralNames.push(name);
			}

			if (name.yog)
			{
				yogNames.push(name);
			}
		}
	}

	/**
	 * Get a random name, optionally matching a specific gender.
	 * Yogscast names have a higher chance of being selected.
	 * 
	 * @param gender "M", "F", "?" (neutral), or null for any gender
	 * @param yogWeight Weight multiplier for Yogscast names (default 3.0 = 3x more likely)
	 * @return Random name entry
	 */
	public static function getRandomName(?gender:String, yogWeight:Float = 3.0):NameEntry
	{
		if (!initialized)
			init();

		// Build weighted pool based on gender
		var pool:Array<NameEntry> = [];

		if (gender == null)
		{
			// Any gender - use all names
			pool = allNames.copy();
		}
		else if (gender == "?")
		{
			// Neutral requested - include neutral + male + female
			pool = neutralNames.copy();
			pool = pool.concat(maleNames);
			pool = pool.concat(femaleNames);
		}
		else
		{
			// Specific gender requested - include that gender + neutral
			var genderPool = (gender == "M") ? maleNames : femaleNames;
			pool = genderPool.copy();
			pool = pool.concat(neutralNames);
		}

		// Add Yogscast names multiple times for weighted selection
		if (yogWeight > 1.0)
		{
			var yogPool = yogNames.filter(function(n)
			{
				// Only add yogs that match the requested gender
				if (gender == null || gender == "?")
					return true;
				return n.gender == gender || n.gender == "?";
			});

			var extraCopies = Math.floor(yogWeight);
			for (i in 1...extraCopies)
			{
				pool = pool.concat(yogPool);
			}
		}

		if (pool.length == 0)
		{
			// Fallback to unknown if no names found
			return {first_name: "Unknown", gender: "?", yog: false};
		}

		// Pick random from weighted pool
		return pool[Std.random(pool.length)];
	}

	/**
	 * Get the sprite frame offset based on gender.
	 * Used to pick appropriate character sprite.
	 * 
	 * @param gender "M", "F", or "?"
	 * @return 0 for male/neutral, 4 for female
	 */
	public static function getFrameOffsetForGender(gender:String):Int
	{
		return (gender == "F") ? 4 : 0;
	}
}
