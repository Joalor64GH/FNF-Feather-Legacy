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
	/**
	 * a Enabled Mod that has priority over other mods
	 * usually being the first one on the sorted mod list
	 */
	public static var dominantMod:ModFormat = null;

	/**
	 * a List of Active Mods that will be taken into account when searching assets
	 * NOTICE: `dominantMod` will have priority over them
	 */
	public static var activeMods:Array<ModFormat> = [];

	/**
	 * a List with all mods, whether they are active or inactive
	 * useful for making a full mod list with all mods available
	 */
	public static var trackedMods:Array<ModFormat> = [];

	/**
	 * List of folders that will not be taken into account when tracking mods
	 */
	public static var ignoreFolders:Array<String> = [];

	public static function getPath(?folder:String, ?type:AssetType):String {
		if (folder != null)
			folder = '/${folder}';

		var modFolder:String = null;
		if (dominantMod != null) {
			if (FileSystem.exists(type.cycleExtensions('mods/${dominantMod.folder}/${folder}')))
				modFolder = dominantMod.folder;
		} else {
			if (activeMods.length > 0) {
				for (i in 0...activeMods.length) {
					if (!ignoreFolders.contains(activeMods[i].folder))
						if (FileSystem.exists(type.cycleExtensions('mods/${activeMods[i].folder}/${folder}')))
							modFolder = activeMods[i].folder;
				}
			}
		}
		if (modFolder != null)
			folder = '/${modFolder}${folder}';

		return type.cycleExtensions('mods${folder}');
	}

	public static function scanMods():Void {
		trackedMods = [];
		activeMods = [];

		// read the mods folder
		if (FileSystem.exists("mods")) {
			// read the mod order file and see if its enabled
			var modArray:Array<String> = Utils.readText("mods/order.txt");
			var modMap:Map<String, Bool> = [];
			for (i in modArray) {
				var splitArray:Array<String> = i.split("||");
				modMap.set(splitArray[0], splitArray[1] == 'true');
			}

			for (mod in FileSystem.readDirectory("mods")) {
				if (!ignoreFolders.contains(mod)) {
					if (FileSystem.exists('mods/${mod}/mod.json')) {
						var modJson:ModFormat = cast tjson.TJSON.parse(File.getContent('mods/${mod}/mod.json'));
						var newMod:ModFormat =
							{
								name: modJson.name,
								description: modJson.description,
								color: FlxColor.fromString(Std.string(modJson.color)),
								folder: mod
							};
						if (modJson.name == null)
							newMod.name = mod;

						trackedMods.push(newMod);
						if (modMap.exists(mod) && modMap.get(mod) == true)
							activeMods.push(newMod);
					}
				}
			}

			trace('Mods: ${trackedMods.length} - Active: ${activeMods.length}');
		}
	}
}
