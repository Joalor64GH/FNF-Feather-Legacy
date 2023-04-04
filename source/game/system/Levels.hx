package game.system;

import sys.FileSystem;
import sys.io.File;

class Levels {
	public static final DEFAULT_DIFFICULTIES:Array<String> = ["easy", "normal", "hard"];
	public static var DIFFICULTIES:Array<String> = [];
	public static var GAME_LEVELS:Array<GameWeek> = [];

	public static function loadLevels():Void {
		GAME_LEVELS = [];

		for (week in Utils.readText(Paths.getPath('data/weeks/order', TXT, true))) {
			if (FileSystem.exists(Paths.getPath('data/weeks/${week}', JSON, true))) {
				var newWeek:GameWeek = cast tjson.TJSON.parse(AssetHandler.getAsset('data/weeks/${week}', JSON, true));

				for (i in 0...newWeek.songs.length) // convert string to color
					newWeek.songs[i].color = FlxColor.fromString(Std.string(newWeek.songs[i].color));

				if (!GAME_LEVELS.contains(newWeek))
					GAME_LEVELS.push(newWeek);
			}
		}

		#if MODDING_ENABLED
		for (modWeek in Utils.readText(core.assets.ModHandler.getPath('data/weeks/order', TXT))) {
			if (modWeek == null)
				return;

			if (FileSystem.exists(core.assets.ModHandler.getPath('data/weeks/${modWeek}', JSON))) {
				var modWeek:GameWeek = cast tjson.TJSON.parse(File.getContent(core.assets.ModHandler.getPath('data/weeks/${modWeek}', JSON)));

				for (i in 0...modWeek.songs.length)
					modWeek.songs[i].color = FlxColor.fromString(Std.string(modWeek.songs[i].color));

				if (!GAME_LEVELS.contains(modWeek))
					GAME_LEVELS.push(modWeek);
			}
		}
		#end
	}
}

typedef GameWeek = {
	var songs:Array<ListableSong>;
	var chars:Array<String>;
	var ?diffs:Array<String>;
	var label:String;
}

typedef ListableSong = {
	var name:String;
	var opponent:String;
	var ?color:FlxColor;
}
