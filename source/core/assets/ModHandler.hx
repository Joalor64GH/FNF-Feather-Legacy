package core.assets;

import sys.FileSystem;
import sys.io.File;

typedef ModFormat = {
	var name:String;
	var description:String;
	var folder:String;
	var ?color:FlxColor;
}

class ModHandler {
	public static var activeMod:ModFormat = null;
	public static var trackedMods:Array<ModFormat> = [];

	public static var ignoreFolders:Array<String> = [];
	public static var disregardedFolders:Array<String> = [];

	public static function getPath(?folder:String, ?type:AssetType):String {
		if (folder != null)
			folder = '/${folder}';

		var modFolder:String = null;
		if (activeMod != null) {
			if (FileSystem.exists(type.cycleExtensions('mods/${activeMod.folder}/${folder}')))
				modFolder = activeMod.folder;
		} else {
			if (trackedMods.length > 0) {
				for (i in 0...trackedMods.length)
					if (FileSystem.exists(type.cycleExtensions('mods/${trackedMods[i].folder}/${folder}')))
						modFolder = trackedMods[i].folder;
			}
		}
		if (modFolder != null)
			folder = '/${modFolder}${folder}';

		return type.cycleExtensions('mods${folder}');
	}

	public static function scanMods():Void {
		trackedMods = [];

		// read the mods folder
		if (FileSystem.exists("mods")) {
			for (mod in FileSystem.readDirectory("mods")) {
				var modJson:String = getPath('${mod}/mod', JSON);

				if (FileSystem.exists(modJson)) {
					var modJson:ModFormat = cast tjson.TJSON.parse(File.getContent(modJson));
					var newMod:ModFormat =
						{
							name: modJson.name,
							description: modJson.description,
							color: modJson.color,
							folder: mod
						};
					newMod.color = FlxColor.fromString(Std.string(modJson.color));

					if (modJson.name == null)
						newMod.name = mod;
					trackedMods.push(newMod);
				}
			}

			trace('Mods: ${trackedMods.length}');
		}
	}
}
