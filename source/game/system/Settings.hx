package game.system;

class Settings {
	/**
	 * TODO: refactor this
	 */
	public static final defaultSettings:Array<Dynamic> = [
		// ["key", value]
		["scrollType", "UP"],
		["ghostTapping", true],
		["noteSplashes", true],
		["judgeCount", false],
		["framerateCap", Std.int(60)],
		["antialiasing", true],
		["infoText", "TIME"], // time, song, none
	];

	public static var mySettings:Array<Dynamic> = [];

	public static function get(name:String):Dynamic {
		for (i in 0...mySettings.length) {
			if (name == mySettings[i][0]) {
				var value:Dynamic = mySettings[i][1];
				return value;
			}
		}
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

		for (i in 0...mySettings.length)
			if (name == mySettings[i][0])
				mySettings[i][1] = value;
	}

	public static function save():Void {
		FlxG.save.bind("Settings", Utils.saveFolder());

		FlxG.save.data.mySettings = mySettings;
		FlxG.save.data.volume = FlxG.sound.volume;
		FlxG.save.data.muted = FlxG.sound.muted;
	}

	public static function load():Void {
		FlxG.save.bind("Settings", Utils.saveFolder());
		mySettings = defaultSettings;

		if (FlxG.save.data.mySettings != null) {
			for (i in 0...FlxG.save.data.mySettings)
				if (FlxG.save.data.mySettings[i] != mySettings[i])
					mySettings[i] = FlxG.save.data.mySettings[i];
		}

		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.muted != null)
			FlxG.sound.muted = FlxG.save.data.muted;

		update();
	}

	public static function update():Void {
		FlxG.save.bind("Settings", Utils.saveFolder());
		Utils.updateFramerateCap(Settings.get("framerateCap"));
	}
}
