package game.options;

import game.system.Settings;

enum abstract OptionType(Int) to Int
{
	var CHECKMARK:OptionType = 0xA;
	var LIST:OptionType = 0xB;
	var NUMBER:OptionType = 0xC;
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
	 * Defines the Option's Type
	 *
	 * CHECKMARK - Boolean,
	 * LIST - String (with an array),
	 * NUMBER - Int/Float
	 */
	public var type:Int = CHECKMARK;

	/**
	 * Contains Strings for Lists
	 */
	public var optionsList:Array<String> = [];

	/**
	 * Defines the minimum value for a number option
	 */
	public var minimum:Float = 0;

	/**
	 * Declares how many decimals a number option has
	 */
	public var decimals:Float = 1;

	/**
	 * Defines the maximum value for a number option
	 */
	public var maximum:Float = 1;

	public function new(name:String, description:String, apiKey:String, type:Int = CHECKMARK):Void
	{
		this.name = name;
		this.description = description;
		this.apiKey = apiKey;
		type = getType();
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
			return NUMBER;
		if (Std.isOfType(Settings.get(apiKey), String))
			return LIST;

		return CHECKMARK;
	}
}
