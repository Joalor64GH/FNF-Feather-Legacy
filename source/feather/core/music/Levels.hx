package feather.core.music;

import flixel.util.typeLimit.OneOfTwo;
import sys.FileSystem;
import sys.io.File;

typedef GameWeek = {
	var songs:Array<ListableSong>;
	var chars:Array<String>;
	var ?diffs:Array<String>;
	var label:String;
}

typedef ListableSong = {
	var name:String;
	var enemy:String;
	var ?color:OneOfTwo<String, FlxColor>; // using OneOfTwo here because YAML data uses strings instead
}

class Levels {
	public static final DEFAULT_DIFFICULTIES:Array<String> = ["easy", "normal", "hard"];
	public static var DIFFICULTIES:Array<String> = [];
	public static var GAME_LEVELS:Array<GameWeek> = [];

	public static function loadLevels():Void {
		GAME_LEVELS = [];

		for (week in Utils.readText(Paths.getPath('data/weeks/order', TXT, true))) {
			if (FileSystem.exists(Paths.getPath('data/weeks/${week}', YAML, true))) {
				var newWeek:GameWeek = cast yaml.Yaml.parse(AssetHandler.getAsset('data/weeks/${week}', YAML, true), yaml.Parser.options().useObjects());

				for (i in 0...newWeek.songs.length) {
					if (newWeek.songs[i].color == null)
						newWeek.songs[i].color = FlxColor.fromInt(0xFFFFFFFF);
					if (Std.isOfType(newWeek.songs[i].color, String))
						newWeek.songs[i].color = FlxColor.fromString(Std.string(newWeek.songs[i].color));
				}

				if (!GAME_LEVELS.contains(newWeek))
					GAME_LEVELS.push(newWeek);
			}
		}

		#if MODDING_ENABLED
		for (i in 0...feather.core.data.ModHandler.activeMods.length) {
			var modName:String = feather.core.data.ModHandler.activeMods[i].folder;

			for (modWeek in Utils.readText(feather.core.data.ModHandler.getFromMod(modName, 'data/weeks/order', TXT))) {
				if (FileSystem.exists(feather.core.data.ModHandler.getFromMod(modName, 'data/weeks/${modWeek}', YAML))) {
					var modWeek:GameWeek = cast yaml.Yaml.parse(File.getContent(feather.core.data.ModHandler.getFromMod(modName, 'data/weeks/${modWeek}',
						YAML)), yaml.Parser.options().useObjects());

					for (i in 0...modWeek.songs.length) {
						if (modWeek.songs[i].color == null)
							modWeek.songs[i].color = FlxColor.fromInt(0xFFFFFFFF);
						if (Std.isOfType(modWeek.songs[i].color, String))
							modWeek.songs[i].color = FlxColor.fromString(Std.string(modWeek.songs[i].color));
					}

					if (!GAME_LEVELS.contains(modWeek))
						GAME_LEVELS.push(modWeek);
				}
			}
		}
		#end
	}
}
