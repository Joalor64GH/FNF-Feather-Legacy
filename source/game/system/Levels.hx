package game.system;

class Levels {
	public static final DEFAULT_DIFFICULTIES:Array<String> = ["easy", "normal", "hard"];

	public static var DIFFICULTIES:Array<String> = [];

	public static var GAME_LEVELS:Array<GameWeek> = [
		{
			songs: [{name: "Tutorial", opponent: "gf", color: 0xFF9271FD}],
			chars: ["", "bf", "gf"],
			label: ""
		},
		{
			songs: [
				{name: "Bopeebo", opponent: "dad", color: 0xFF9271FD},
				{name: "Fresh", opponent: "dad", color: 0xFF9271FD},
				{name: "Dadbattle", opponent: "dad", color: 0xFF9271FD}
			],
			chars: ["dad", "bf", "gf"],
			label: "Daddy Dearest"
		},
		{
			songs: [
				{name: "Spookeez", opponent: "spooky-kids", color: 0xFF223344},
				{name: "South", opponent: "spooky-kids", color: 0xFF223344},
				{name: "Monster", opponent: "lemon-monster", color: 0xFF223344}
			],
			chars: ["spooky-kids", "bf", "gf"],
			label: "Spooky Month"
		},
		{
			songs: [
				{name: "Pico", opponent: "pico", color: 0xFF941653},
				{name: "Philly", opponent: "pico", color: 0xFF941653},
				{name: "Blammed", opponent: "pico", color: 0xFF941653}
			],
			chars: ["pico", "bf", "gf"],
			label: "PICO"
		},
		{
			songs: [
				{name: "Satin-Panties", opponent: "mom", color: 0xFFFC96B7},
				{name: "High", opponent: "mom", color: 0xFFFC96B7},
				{name: "MILF", opponent: "mom", color: 0xFFFC96B7}
			],
			chars: ["mom", "bf", "gf"],
			label: "MOMMY MUST MURDER"
		},
		{
			songs: [
				{name: "Cocoa", opponent: "parents", color: 0xFFA0D1FF},
				{name: "Eggnog", opponent: "parents", color: 0xFFA0D1FF},
				{name: "Winter-Horrorland", opponent: "lemon-monster", color: 0xFFA0D1FF}
			],
			chars: ["parents", "bf", "gf"],
			label: "RED SNOW"
		},
		{
			songs: [
				{name: "Senpai", opponent: "senpai", color: 0xFFFF78BF},
				{name: "Roses", opponent: "senpai", color: 0xFFFF78BF},
				{name: "Thorns", opponent: "spirit", color: 0xFFFF78BF}
			],
			chars: ["senpai", "bf", "gf"],
			label: "Hating Simulator ft. Moawling"
		},
		{
			songs: [
				{name: "Ugh", opponent: "tankman", color: 0xFFF6B604},
				{name: "Guns", opponent: "tankman", color: 0xFFF6B604},
				{name: "Stress", opponent: "tankman", color: 0xFFF6B604}
			],
			chars: ["tankman", "bf", "gf"],
			label: "TANKMAN"
		}
	];
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
