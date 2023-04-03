package core;

class ScriptHandler extends SScript {
	public var presets:Array<Dynamic> = [];

	public function new(file:String, ?myPresets:Array<Dynamic>):Void {
		super(file);

		// default imports
		// presets.push(core.assets.AssetHandler;
		// presets.push(core.assets.Paths);
		presets.push(flixel.FlxG);
		presets.push(flixel.FlxSprite);
		presets.push(flixel.math.FlxMath);
		presets.push(flixel.tweens.FlxEase);
		presets.push(flixel.tweens.FlxTween);
		// presets.push(flixel.util.FlxColor);
		presets.push(flixel.util.FlxTimer);
		presets.push(StringTools);
		presets.push(core.Utils);

		if (myPresets != null && myPresets.length > 0)
			for (i in 0...myPresets.length)
				presets.push(myPresets[i]);
	}

	public override function preset():Void {
		super.preset();

		for (i in 0...presets.length)
			setClass(presets[i]);
	}
}
