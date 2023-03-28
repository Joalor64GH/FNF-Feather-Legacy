package game.options;

import game.system.api.Settings;

enum abstract OptionType(Int) to Int
{
	var CHECKMARK:OptionType = 0xA;
	var LIST:OptionType = 0xB;
	var NUMBER:OptionType = 0xC;
}

class Option
{
	public var name:String;
	public var description:String;

	/**
	 * Variable Name for the Option
	 */
	public var apiKey:String;

	public var type:Int = CHECKMARK;

	/**
	 * Contains Strings for Lists, may contain ints/floats for number options
	 */
	public var optionsList:Array<Dynamic> = [];

	public function new(name:String, description:String, apiKey:String, type:Int = CHECKMARK, ?optionsList:Array<Dynamic>):Void
	{
		this.name = name;
		this.description = description;
		this.apiKey = apiKey;
		this.optionsList = optionsList;
	}
}
