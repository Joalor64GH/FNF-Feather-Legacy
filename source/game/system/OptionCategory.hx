package game.system;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

class OptionCategory extends FlxGroup {
	public var title:String;
	public var optionObjects:FlxTypedGroup<FlxText>;
	public var options:Array<Option>;

	public function new(x:Float = 0, y:Float = 0, title:String, options:Array<Option>):Void {
		super();

		this.title = title;
		this.options = options;

		optionObjects = new FlxTypedGroup<FlxText>();
		for (i in 0...options.length) {
			var opt:FlxText = new FlxText(x, (40 * i) + y, 0, '${options[i].name}: ${getValueText(i)}');
			opt.setFormat(Paths.font('vcr'), 32, 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
			opt.ID = i;
			opt.alpha = 0;
			optionObjects.add(opt);
		}
		add(optionObjects);
	}

	public function getValueText(index:Int):String {
		return switch (options[index].value) {
			case "true": "ON";
			case "false": "OFF";
			default: options[index].value;
		}
	}
}
