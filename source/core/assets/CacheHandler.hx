package core.assets;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.Assets as OpenFLAssets;

class CacheHandler
{
	public static var cachedGraphics:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var cachedSounds:Map<String, Sound> = new Map<String, Sound>();

	public static var trackedIDs:Array<String> = [];

	public static function getGraphicData(path:String):FlxGraphic
	{
		if (!cachedGraphics.exists(path))
		{
			var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path), false, path);
			newGraphic.persist = true;
			cachedGraphics.set(path, newGraphic);
			trackedIDs.push(path);
			return newGraphic;
		}
		else if (cachedGraphics.get(path) != null)
			return cachedGraphics.get(path);

		trace('image asset at "${path}" is returning null, called from "${Type.getClass(FlxG.state)}"');
		return null;
	}

	public static function getSoundData(path:String):Sound
	{
		if (!cachedSounds.exists(path))
		{
			var newSound:Sound = Sound.fromFile(path);
			cachedSounds.set(path, newSound);
			trackedIDs.push(path);
			return cachedSounds.get(path);
		}
		else
		{
			if (cachedSounds.get(path) != null)
				return cachedSounds.get(path);
		}

		trace('sound asset at "${path}" is returning null, called from "${Type.getClass(FlxG.state)}"');
		return null;
	}

	public static function purge(stored:Bool = false):Void
	{
		_purgeUnused();
		if (stored)
			_purgeStored();
		SysGC.run(true);
	}

	static function _purgeStored():Void
	{
		@:privateAccess {
			for (data in FlxG.bitmap._cache.keys())
			{
				if (OpenFLAssets.cache.hasBitmapData(data) && !trackedIDs.contains(data))
				{
					OpenFLAssets.cache.clear(data);
					FlxG.bitmap._cache.remove(data);
				}
			}
		}

		for (data in cachedSounds.keys())
		{
			if (OpenFLAssets.cache.hasSound(data) && !trackedIDs.contains(data))
			{
				OpenFLAssets.cache.clear(data);
				cachedSounds.remove(data);
			}
		}

		trackedIDs = [];
	}

	static function _purgeUnused():Void
	{
		for (data in cachedGraphics.keys())
		{
			if (OpenFLAssets.cache.hasBitmapData(data))
			{
				OpenFLAssets.cache.clear(data);
				@:privateAccess FlxG.bitmap._cache.remove(data);
			}
			cachedGraphics.remove(data);
		}
	}
}
