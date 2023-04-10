package feather.core.options;

enum abstract OptionType(Int) to Int {
	var Checkmark:OptionType = 0xA;
	var StringList:OptionType = 0xB;
	var Number:OptionType = 0xC;
}

/**
 * Object that represents an Option
 */
class Option {
	public var name:String;
	public var description:String;

	/**
	 * the Current value for ths Option
	 */
	public var value(get, set):Dynamic;

	/**
	 * Variable Name for the Option
	 */
	public var apiKey:String;

	/**
	 * Whether the option is locked from being activated on the pause menu
	 */
	public var lockOnPause:Bool = false;

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
	 * Defines how many decimals a number option has
	 */
	public var decimals:Int = 1;

	/**
	 * Defines the maximum value for a number option
	 */
	public var maximum:Int = 1;

	/**
	 * a Function that gets ran whenever you set an option a new value
	 */
	public var onSet:Void->Void = null;

	public function new(name:String, description:String, apiKey:String, ?optionsList:Array<String>, lockOnPause:Bool = false):Void {
		this.name = name;
		this.description = description;

		this.optionsList = optionsList;
		this.lockOnPause = lockOnPause;

		this.apiKey = apiKey;
		this.type = getType();
	}

	public inline function get_value():Dynamic {
		return UserSettings.get(apiKey);
	}

	public inline function set_value(Value:Dynamic):Dynamic {
		UserSettings.set(apiKey, Value);
		if (onSet != null)
			onSet();

		return Value;
	}

	@:noCompletion inline function getType():Int {
		if (Std.isOfType(UserSettings.get(apiKey), Int) || Std.isOfType(UserSettings.get(apiKey), Float))
			return Number;

		if (Std.isOfType(UserSettings.get(apiKey), String))
			return StringList;

		return Checkmark;
	}
}
