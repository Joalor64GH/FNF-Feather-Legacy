package feather.core.handlers;

import flixel.graphics.frames.FlxAtlasFrames;
import sys.FileSystem;
import sys.io.File;

enum EngineOrigin {
	/**
	 * Characters: JSON
	 * Charts: heavily modified base
	 */
	PSYCH_ENGINE;

	/**
	 * Characters: Scripts (hscript)
	 * Charts: Same as base
	 */
	FOREVER_ENGINE;

	/**
	 * Characters: JSON
	 * Charts: unique format
	 */
	CROW_ENGINE;
}

class AssetHandler {
	public static function getPath(?folder:String, ?type:AssetType, ?disregardMods:Bool = false):String {
		var pathBase:String = 'assets';
		if (folder != null) {
			if (folder.startsWith("assets"))
				pathBase = '';
			folder = '/${folder}';
		}

		var returnPath:String = type.cycleExtensions('${pathBase}${folder}');

		// prioritize mod assets
		#if MODDING_ENABLED
		if (!disregardMods)
			if (FileSystem.exists(ModHandler.getPath(folder, type)))
				returnPath = ModHandler.getPath(folder, type);
		#end

		return returnPath;
	}

	public static function getAsset(folder:String, ?type:AssetType, ?disregardMods:Bool = false):Dynamic {
		var finalPath:String = getPath(folder, type, disregardMods);

		return switch (type) {
			case IMAGE: CacheHandler.getGraphicData(finalPath);
			case SOUND: CacheHandler.getSoundData(finalPath);
			case XML: FlxAtlasFrames.fromSparrow(getAsset(folder, IMAGE), File.getContent(getPath(folder, XML)));
			case TXT: FlxAtlasFrames.fromSpriteSheetPacker(getAsset(folder, IMAGE), getPath(folder, TXT));
			case JSON | YAML:
				var file = sys.io.File.getContent(finalPath);

				if (type == JSON)
					while (!file.endsWith("}"))
						file = file.substr(0, file.length - 1);

				file;
			case JSON_ATLAS:
				return flxanimate.frames.FlxAnimateFrames.fromJson(getAsset(folder, JSON), getAsset(folder, IMAGE));
			default: finalPath;
		}
	}

	public static function preload(file:String, type:AssetType = IMAGE):Void {
		return switch (type) {
			case IMAGE: CacheHandler.getGraphicData(file);
			case SOUND: CacheHandler.getSoundData(file);
			default:
		}
	}

	public static function getExtensionsFor(type:AssetType):Array<String>
		return type.getExtension();
}

enum abstract AssetType(String) to String from String {
	var FONT:AssetType = 'font';
	var IMAGE:AssetType = 'image';
	var SOUND:AssetType = 'sound';
	// TEXT TYPES
	var XML:AssetType = 'xml';
	var JSON:AssetType = 'json';
	var YAML:AssetType = 'yaml';
	var SCRIPT:AssetType = 'script';
	var TXT:AssetType = 'txt';
	var JSON_ATLAS:AssetType = 'json_atlas';

	public function cycleExtensions(path:String):String {
		if (getExtension() != null) {
			for (i in getExtension())
				if (sys.FileSystem.exists('${path}${i}'))
					return '${path}${i}';
		}

		return '${path}';
	}

	public function getExtension():Array<String> {
		return switch (this) {
			case IMAGE: ['.png', '.jpg', '.bmp'];
			case SOUND: ['.mp3', '.ogg', '.wav'];
			case SCRIPT: ['.hx', '.hxs', '.hxc', '.hscript', '.hxclass'];
			case FONT: ['.ttf', '.otf'];
			case TXT: ['.txt'];
			case XML: ['.xml'];
			case JSON: ['.json'];
			case YAML: ['.yaml', '.yml'];
			default: null;
		}
	}

	public function toOpenFL():openfl.utils.AssetType {
		return switch (this) {
			case IMAGE: openfl.utils.AssetType.IMAGE;
			case SOUND: openfl.utils.AssetType.SOUND;
			case TXT | XML | JSON | SCRIPT: openfl.utils.AssetType.TEXT;
			case FONT: openfl.utils.AssetType.FONT;
			default: openfl.utils.AssetType.BINARY;
		}
	}
}

// haha u looked.
