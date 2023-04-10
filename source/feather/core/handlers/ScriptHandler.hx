package feather.core.handlers;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import sys.io.File;

class ScriptHandler extends SScript {
	public var presets:Array<Dynamic> = [];
	public var folder:String = null;

	public function new(file:String, ?_folder:String = null, ?myPresets:Array<Dynamic>):Void {
		super(file);

		folder = _folder;

		// default imports
		presets.push(flixel.FlxG);
		presets.push(flixel.FlxSprite);
		presets.push(flixel.math.FlxMath);
		presets.push(flixel.tweens.FlxEase);
		presets.push(flixel.tweens.FlxTween);
		presets.push(flixel.util.FlxTimer);
		presets.push(StringTools);
		presets.push(feather.core.Utils);

		if (myPresets != null && myPresets.length > 0)
			for (i in 0...myPresets.length)
				presets.push(myPresets[i]);

		if (folder != null)
			set('Paths', new ScriptPaths(folder));

		// @:privateAccess trace(parsingExceptions);
	}

	public override function preset():Void {
		super.preset();

		for (i in 0...presets.length)
			setClass(presets[i]);
	}
}

/**
 * Copy of the Paths class, extended for scripts
 */
class ScriptPaths {
	public var location:String = null;

	public function new(_location:String):Void {
		location = _location;
		trace('created new local path on ${_location}');
	}

	public inline function getPath(path:String, ?type:AssetType):String {
		// trace('path requested by ${location} was ${path}');
		return type.cycleExtensions('${location}/${path}');
	}

	public inline function font(font:String):String
		return getPath('fonts/${font}', FONT);

	public inline function image(image:String):FlxGraphic
		return CacheHandler.getGraphicData(getPath('images/${image}', IMAGE));

	public inline function sound(sound:String):Sound
		return CacheHandler.getSoundData(getPath('sounds/${sound}', SOUND));

	public inline function getSparrowAtlas(xml:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(image('${xml}'), File.getContent(getPath('images/${xml}', XML)));

	public inline function getPackerAtlas(txt:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSpriteSheetPacker(image('${txt}'), getPath('images/${txt}', TXT));
}
