package core.assets;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;

/**
 * Compatibility with Base Game
 */
class Paths
{
	public static inline function getPath(path:String, ?type:AssetType):String
		return AssetHandler.getPath(path, type);

	public static inline function getPreloadPath(path:String, ?type:AssetType):String
		return getPath(path, type);

	public static inline function image(image:String):Dynamic
		return AssetHandler.getAsset('images/${image}', IMAGE);

	public static inline function sound(sound:String):Sound
		return AssetHandler.getAsset('sounds/${sound}', SOUND);

	public static inline function music(music:String):Sound
		return AssetHandler.getAsset('music/${music}', SOUND);

	public static inline function font(font:String):String
		return AssetHandler.getAsset('data/fonts/${font}', FONT);

	public static inline function inst(song:String):String
		return AssetHandler.getPath('data/songs/audio/${song}/Inst', SOUND);

	public static inline function vocals(song:String):String
	{
		if (AssetHandler.exists(AssetHandler.getPath('data/songs/audio/${song}/Voices', SOUND)))
			return AssetHandler.getPath('data/songs/audio/${song}/Voices', SOUND);
		return null;
	}

	public static inline function getSparrowAtlas(xml:String):FlxAtlasFrames
		return AssetHandler.getAsset('images/${xml}', XML);

	public static inline function getPackerAtlas(txt:String):FlxAtlasFrames
		return AssetHandler.getAsset('images/${txt}', TXT);
}
