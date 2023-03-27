package core.assets;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFLAssets;

using StringTools;

class AssetHandler
{
	public static function getPath(?folder:String, ?type:AssetType):String
	{
		if (folder != null)
			folder = '/${folder}';
		return type.cycleExtensions('assets${folder}');
	}

	public static function getAsset(folder:String, ?type:AssetType):Dynamic
	{
		var finalPath:String = getPath(folder, type);

		return switch (type)
		{
			case IMAGE: CacheHandler.getGraphicData(finalPath);
			case SOUND: CacheHandler.getSoundData(finalPath);
			case XML: FlxAtlasFrames.fromSparrow(getPath(folder, IMAGE), getPath(folder, XML));
			case TXT: FlxAtlasFrames.fromSpriteSheetPacker(getPath(folder, IMAGE), getPath(folder, TXT));
			case JSON:
				var json = OpenFLAssets.getText(finalPath);
				while (!json.endsWith("}"))
					json = json.substr(0, json.length - 1);
				json;
			default: finalPath;
		}
	}
}

@:enum abstract AssetType(String) to String from String
{
	var FONT:AssetType = 'font';
	var IMAGE:AssetType = 'image';
	var SOUND:AssetType = 'sound';
	// TEXT TYPES
	var XML:AssetType = 'xml';
	var JSON:AssetType = 'json';
	var TXT:AssetType = 'txt';

	public function cycleExtensions(path:String):String
	{
		if (getExtension() != null)
		{
			for (i in getExtension())
				if (OpenFLAssets.exists('${path}${i}'))
					return '${path}${i}';
		}

		return '${path}';
	}

	public function getExtension():Array<String>
	{
		return switch (this)
		{
			case IMAGE: ['.png', '.jpg', '.bmp'];
			case SOUND: ['.mp3', '.ogg', '.wav'];
			case FONT: ['.ttf', '.otf'];
			case TXT: ['.txt'];
			case XML: ['.xml'];
			case JSON: ['.json'];
			default: null;
		}
	}

	public function toOpenFL():openfl.utils.AssetType
	{
		return switch (this)
		{
			case IMAGE: openfl.utils.AssetType.IMAGE;
			case SOUND: openfl.utils.AssetType.SOUND;
			case TXT | XML | JSON: openfl.utils.AssetType.TEXT;
			case FONT: openfl.utils.AssetType.FONT;
			default: openfl.utils.AssetType.BINARY;
		}
	}
}
