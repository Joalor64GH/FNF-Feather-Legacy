package game.options;

import game.system.Settings;

enum abstract OptionType(Int) to Int
{
	var Checkmark:OptionType = 0xA;
	var StringList:OptionType = 0xB;
	var Number:OptionType = 0xC;
}

/**
 * Object that represents an Option
 */
class Option
{
	public var name:String;
	public var description:String;

	/**
	 * Variable Name for the Option
	 */
	public var apiKey:String;

	/**
	 * Whether the option should need a song reset
	 */
	public var mustReset:Bool = false;

	/**
	 * Defines the Option's Type
	 *
	 * CHECKMARK - Boolean,
	 * LIST - String (with an array),
	 * NUMBER - Int/Float
	 */
	public var type:Int = Checkmark;

	/**
	 * Contains Strings for Lists
	 */
	public var optionsList:Array<String> = [];

	/**
	 * Defines the minimum value for a number option
	 */
	public var minimum:Int = 0;

	/**
	 * Declares how many decimals a number option has
	 */
	public var decimals:Float = 1;

	/**
	 * Defines the maximum value for a number option
	 */
	public var maximum:Int = 1;

	public function new(name:String, description:String, apiKey:String, ?optionsList:Array<String>):Void
	{
		this.name = name;
		this.description = description;
		this.optionsList = optionsList;
		this.apiKey = apiKey;
		this.type = getType();
	}

	public inline function getValue():Dynamic
	{
		return Settings.get(apiKey);
	}

	public inline function setValue(Value:Dynamic):Void
	{
		Settings.set(apiKey, Value);
	}

	@:noCompletion inline function getType():Int
	{
		if (Std.isOfType(Settings.get(apiKey), Int) || Std.isOfType(Settings.get(apiKey), Float))
			return Number;

		if (Std.isOfType(Settings.get(apiKey), String))
			return StringList;

		return Checkmark;
	}
}
