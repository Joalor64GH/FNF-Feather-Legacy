package feather.core.handlers;

import sys.FileSystem;
import sys.io.File;

typedef ModFormat = {
	var name:String;
	var description:String;
	var folder:String;
	var ?color:FlxColor;
}

typedef ModLoadingFormat = {
	var name:String;
	var active:Bool;
	var ignoreFolders:Array<String>; // TODO
}

class ModHandler {
	/**
	 * Map that stores all loaded mod data from the YAML data file
	**/
	public static var modMap:Map<String, ModLoadingFormat> = [];

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

	@:keep public static inline function getPath(?folder:String, ?type:AssetType):String {
		var pathBase:String = 'mods';
		if (folder != null) {
			if (folder.startsWith("mods"))
				pathBase = '';
			folder = '/${folder}';
		}

		var modFolder:String = null;
		if (dominantMod != null) {
			if (FileSystem.exists(type.cycleExtensions('mods/${dominantMod.folder}/${folder}')))
				modFolder = dominantMod.folder;
		} else {
			if (activeMods.length > 0) {
				for (i in 0...activeMods.length) {
					if (!ignoreFolders.contains(activeMods[i].folder)) {
						if (FileSystem.exists(type.cycleExtensions('mods/${activeMods[i].folder}/${folder}')))
							modFolder = activeMods[i].folder;
					}
				}
			}
		}
		if (modFolder != null)
			folder = '/${modFolder}${folder}';

		return type.cycleExtensions('${pathBase}${folder}');
	}

	public static function getFromMod(mod:String, ?folder:String, ?type:AssetType):String {
		var pathBase:String = 'mods';
		var pathExtend:String = '';
		if (folder != null) {
			if (folder.startsWith("mods"))
				pathBase = '';
			pathExtend = '/${mod}/${folder}';
		}

		return type.cycleExtensions('${pathBase}${pathExtend}');
	}

	@:keep private static inline function checkIgnoreList(modData:ModLoadingFormat):Array<String> {
		var myModFolders:Array<String> = [];
		if (modData != null && modData.active) {
			if (modData.ignoreFolders != null)
				for (i in 0...modData.ignoreFolders.length)
					myModFolders.push(modData.ignoreFolders[i]);
		}
		return myModFolders;
	}

	@:keep public static inline function scanMods():Void {
		modMap.clear();
		trackedMods = [];
		activeMods = [];

		// read the mods folder
		if (FileSystem.exists("mods")) {
			// read the mod order file and see if its enabled
			var modList:Array<ModLoadingFormat> = cast yaml.Yaml.parse(File.getContent('mods/order.yaml'), yaml.Parser.options().useObjects());
			trace(modList);
			for (i in 0...modList.length)
				if (FileSystem.exists('mods/${modList[i].name}'))
					modMap.set(modList[i].name, modList[i]);

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
						if (modMap.exists(mod) && modMap.get(mod).active)
							activeMods.push(newMod);
					}
				}
			}
			trace('Mods: ${trackedMods.length} - Active: ${activeMods.length}');
		}
	}
}
