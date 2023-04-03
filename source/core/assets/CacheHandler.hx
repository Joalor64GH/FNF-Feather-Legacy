package core.assets;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.Assets as OpenFLAssets;
#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

/**
 * fuck
 */
enum abstract PurgeDefinition(String) to String {
	var STORED_IMAGES:PurgeDefinition = 'stored_images';
	var UNUSED_IMAGES:PurgeDefinition = 'unused_images';
	var CACHED_SOUNDS:PurgeDefinition = 'cached_sounds';
}

class CacheHandler {
	public static var cachedGraphics:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var cachedSounds:Map<String, Sound> = new Map<String, Sound>();

	public static var trackedIDs:Array<String> = [];

	public static function getGraphicData(path:String):FlxGraphic {
		if (!cachedGraphics.exists(path)) {
			var newGraphic:FlxGraphic = null;

			try newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path), false, path) catch (e:haxe.Exception) {
				newGraphic = FlxGraphic.fromRectangle(100, 100, 0xFFAAAAAA);
				trace('image graphic at "${path}" could not be loaded.');
			}

			newGraphic.persist = true;
			cachedGraphics.set(path, newGraphic);
			trackedIDs.push(path);
			return newGraphic;
		} else if (cachedGraphics.get(path) != null)
			return cachedGraphics.get(path);

		trace('image asset at "${path}" is returning null, called from "${Type.getClass(FlxG.state)}"');
		return null;
	}

	public static function getSoundData(path:String):Sound {
		if (!cachedSounds.exists(path)) {
			var newSound:Sound = Sound.fromFile(path);
			cachedSounds.set(path, newSound);
			trackedIDs.push(path);
			return cachedSounds.get(path);
		} else {
			if (cachedSounds.get(path) != null)
				return cachedSounds.get(path);
		}

		trace('sound asset at "${path}" is returning null, called from "${Type.getClass(FlxG.state)}"');
		return null;
	}

	public static function purge(?definitions:Array<PurgeDefinition>):Void {
		// definitions are optional
		if (definitions == null)
			definitions = [UNUSED_IMAGES, CACHED_SOUNDS];

		var funcsToExec:Array<Void->Void> = [];

		if (definitions.contains(STORED_IMAGES))
			funcsToExec.push(_purgeStored);
		if (definitions.contains(CACHED_SOUNDS))
			funcsToExec.push(_purgeSounds);
		if (definitions.contains(UNUSED_IMAGES))
			funcsToExec.push(_purgeUnused);

		if (funcsToExec.length > 0)
			for (i in 0...funcsToExec.length)
				funcsToExec[i]();
	}

	static function _purgeStored():Void {
		@:privateAccess {
			for (data in FlxG.bitmap._cache.keys()) {
				if (!trackedIDs.contains(data)) {
					var dataGraphic:FlxGraphic = FlxG.bitmap._cache.get(data);
					OpenFLAssets.cache.removeBitmapData(data);
					OpenFLAssets.cache.clear(data);
					FlxG.bitmap._cache.remove(data);
					dataGraphic.destroy();
				}
			}
		}
		trackedIDs = [];
	}

	static function _purgeUnused():Void {
		for (data in cachedGraphics.keys()) {
			@:privateAccess
			{
				if (!trackedIDs.contains(data)) {
					var dataGraphic:FlxGraphic = cachedGraphics.get(data);
					OpenFLAssets.cache.removeBitmapData(data);
					OpenFLAssets.cache.clear(data);
					FlxG.bitmap._cache.remove(data);
					cachedGraphics.remove(data);
					dataGraphic.destroy();
				}
			}
		}
		gcRun(true);
	}

	static function _purgeSounds():Void {
		for (data in cachedSounds.keys()) {
			if (!trackedIDs.contains(data)) {
				OpenFLAssets.cache.clear(data);
				cachedSounds.remove(data);
			}
		}
	}

	public static function gcEnable():Void {
		#if (cpp || hl) Gc.enable(true); #end
	}

	public static function gcDisable():Void {
		#if (cpp || hl) Gc.enable(false); #end
	}

	public static function gcRun(major:Bool = false):Void {
		#if (cpp || java || neko)
		Gc.run(major);
		#elseif hl
		Gc.major();
		#else
		openfl.system.System.gc();
		#end

		#if cpp
		Gc.compact();
		#end
	}
}
