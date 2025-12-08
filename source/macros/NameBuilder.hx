package macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class NameBuilder
{
	public static macro function build():Array<Field>
	{
		var fields = Context.getBuildFields();

		if (!Context.defined("display"))
		{
			// Read the JSON file at compile time
			var filePath = "assets/data/names.json";
			var content = sys.io.File.getContent(filePath);

			// Parse JSON at compile time
			var names:Array<Dynamic> = haxe.Json.parse(content);

			// trace('NameBuilder macro: Loaded ${names.length} names from ${filePath} at compile time');

			// Convert each name entry into an expression
			var nameEntries:Array<Expr> = [];
			for (name in names)
			{
				var firstName = name.first_name;
				var gender = name.gender;
				var yog = name.yog;

				nameEntries.push(macro {first_name: $v{firstName}, gender: $v{gender}, yog: $v{yog}});
			}

			// Create the allNames field with embedded data array
			fields.push({
				pos: Context.currentPos(),
				name: "allNames",
				meta: null,
				kind: FVar(macro :Array<NameEntry>, macro $a{nameEntries}),
				doc: "Compile-time embedded name data from names.json",
				access: [APublic, AStatic]
			});
		}

		return fields;
	}
}
