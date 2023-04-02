package core.assets;

import sys.FileSystem;
import sys.io.File;

typedef ModFormat = {
	var ?name:String;
	var ?description:String;
	var ?color:FlxColor;
}

class ModHandler {
	public static var activeMod:ModFormat = null;
	public static var trackedMods:Array<ModFormat> = [];
	public static var modFolders:Array<String> = [];

	public static function getPath(?folder:String, ?type:AssetType):String {
		if (folder != null)
			folder = '/${folder}';

		var path:String = type.cycleExtensions('mods${folder}');
		return path;
	}

	public static function scanMods():Void {
		trackedMods = [];
		modFolders = [];

		// read the mods folder
		if (FileSystem.exists("mods")) {
			for (mod in FileSystem.readDirectory("mods")) {
				var modJson:String = getPath('${mod}/mod', JSON);

				if (FileSystem.exists(modJson)) {
					var modJson:ModFormat = cast tjson.TJSON.parse(File.getContent(modJson));
					var newMod:ModFormat = {name: modJson.name, description: modJson.description, color: FlxColor.fromString(Std.string(modJson.color))};
					if (modJson.name == null)
						newMod.name = mod;
					trackedMods.push(newMod);
				}

				modFolders.push(mod);
			}

			trace('Mods: ${trackedMods.length}');
		}
	}
}
