package game.system;

class UserSettings {
	/**
	 * when creating UserSettings, do remember that a value can affect it's type
	 * for instance, String values will require you to assign an array to your option
	 * integers and floats will require you to assign a minimum and maximum value to your option
	 * and so on...
	 */
	@:noPrivateAccess
	private static var defaultPreferences:Map<String, Dynamic> = [
		// ACCESSIBILITY
		"antialiasing" => true,
		"flasingLights" => true,
		"framerateCap" => 60,
		"lowMemory" => false,
		// GAMEPLAY AND APPEARANCE
		"centerScroll" => false,
		"ghostTapping" => true,
		"noteSplashes" => true,
		"scrollType" => "UP",
		"infoText" => "TIME",
	];

	public static var myPreferences:Map<String, Dynamic> = [];

	public static function get(name:String):Dynamic {
		if (myPreferences.exists(name))
			return myPreferences.get(name);
		return null;
	}

	public static function set(name:String, value:Dynamic):Void {
		if (Std.isOfType(value, String)) {
			value = switch (value) {
				case "ON": true;
				case "OFF": false;
				default: value;
			}
		}

		if (myPreferences.exists(name))
			myPreferences.set(name, value);
	}

	public static function save():Void {
		FlxG.save.bind("UserSettings", Utils.saveFolder());

		FlxG.save.data.myPreferences = myPreferences;
		FlxG.save.data.volume = FlxG.sound.volume;
		FlxG.save.data.muted = FlxG.sound.muted;
	}

	public static function load():Void {
		FlxG.save.bind("UserSettings", Utils.saveFolder());
		myPreferences = defaultPreferences.copy();

		if (FlxG.save.data.myPreferences != null) {
			for (key in defaultPreferences.keys()) {
				if (FlxG.save.data.myPreferences.exists(key) && myPreferences.get(key) != FlxG.save.data.myPreferences.get(key))
					myPreferences.set(key, FlxG.save.data.myPreferences.get(key));
			}
		}

		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.muted != null)
			FlxG.sound.muted = FlxG.save.data.muted;

		update();
	}

	public static function update():Void {
		FlxG.save.bind("UserSettings", Utils.saveFolder());
		Utils.updateFramerateCap(UserSettings.get("framerateCap"));
	}
}
