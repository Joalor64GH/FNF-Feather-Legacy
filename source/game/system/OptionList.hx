package game.system;

/**
 * Temp class
 */
class OptionList {
	public static function get():Array<Option> {
		var options:Array<Option> = [];

		options.push(new Option("Scroll Type", "In which direction should notes spawn?", "scrollType", ["UP", "DOWN"], true));
		options.push(new Option("Ghost Tapping", "If mashing keys should be allowed during gameplay.", "ghostTapping"));
		options.push(new Option("Note Splashes", "If the firework effect should appear when hitting \"Sick\"s on Notes.", "noteSplashes"));

		var option:Option = new Option("Framerate Cap", "Define a Framerate Cap.", "framerateCap");
		option.minimum = 30;
		option.decimals = 5;
		option.maximum = 160;
		options.push(option);

		options.push(new Option("Info Display", "Choose what to display on the info text (usually shows time)", "infoText", ["TIME", "SONG", "NONE"]));

		return options;
	}
}
