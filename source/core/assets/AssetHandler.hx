package core.assets;

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
		if (folder != null)
			folder = '/${folder}';

		var returnPath:String = type.cycleExtensions('assets${folder}');

		// prioritize mod assets
		#if MODDING_ENABLED
		if (!disregardMods) {
			if (ModHandler.activeMod != null) // prioritize the active mod
				if (FileSystem.exists(ModHandler.getPath('${ModHandler.activeMod}${folder}', type)))
					returnPath = ModHandler.getPath('${ModHandler.activeMod}${folder}', type);

			if (ModHandler.modFolders.length > 0) { // else just try and search everywhere
				for (i in 0...ModHandler.modFolders.length)
					if (FileSystem.exists(ModHandler.getPath('${ModHandler.modFolders[i]}${folder}', type)))
						returnPath = ModHandler.getPath('${ModHandler.modFolders[i]}${folder}', type);
			}
		}
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
			case JSON:
				var json = sys.io.File.getContent(finalPath);
				while (!json.endsWith("}"))
					json = json.substr(0, json.length - 1);
				json;
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
}

enum abstract AssetType(String) to String from String {
	var FONT:AssetType = 'font';
	var IMAGE:AssetType = 'image';
	var SOUND:AssetType = 'sound';
	// TEXT TYPES
	var XML:AssetType = 'xml';
	var JSON:AssetType = 'json';
	var TXT:AssetType = 'txt';

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
			case FONT: ['.ttf', '.otf'];
			case TXT: ['.txt'];
			case XML: ['.xml'];
			case JSON: ['.json'];
			default: null;
		}
	}

	public function toOpenFL():openfl.utils.AssetType {
		return switch (this) {
			case IMAGE: openfl.utils.AssetType.IMAGE;
			case SOUND: openfl.utils.AssetType.SOUND;
			case TXT | XML | JSON: openfl.utils.AssetType.TEXT;
			case FONT: openfl.utils.AssetType.FONT;
			default: openfl.utils.AssetType.BINARY;
		}
	}
}

// haha u looked.
