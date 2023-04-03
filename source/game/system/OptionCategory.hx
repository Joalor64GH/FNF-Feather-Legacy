package game.system;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

class OptionCategory extends FlxSpriteGroup {
	public var title:String;
	public var optionObjects:FlxTypedGroup<FlxText>;
	public var options:Array<Option>;

	public function new(x:Float, y:Float, title:String, options:Array<Option>):Void {
		super(x, y);

		this.title = title;
		this.options = options;

		optionObjects = new FlxTypedGroup<FlxText>();
		for (i in 0...options.length) {
			var opt:FlxText = new FlxText(0, (40 * i), 0, '${options[i].name}: ${getValueText(i)}');
			opt.setFormat(Paths.font('vcr'), 32, (onPause && options[i].lockOnPause) ? 0xFFFFFF00 : 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
			opt.ID = i;
			optionObjects.add(opt);
		}
		add(optionObjects);
		scrollFactor.set();
	}

	public function getValueText(index:Int):String {
		return switch (options[index].value) {
			case "true": "ON";
			case "false": "OFF";
			default: options[index].value;
		}
	}
}
