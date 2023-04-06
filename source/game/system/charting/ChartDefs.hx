package game.system.charting;

typedef ChartFormat = {
	var name:String;
	var metadata:ChartMeta;
	var sections:Array<ChartSection>;
	var generatedFrom:String;
}

typedef ChartMeta = {
	var player:String;
	var opponent:String;
	var ?crowd:String; // defaults to "gf"
	var ?stage:String; // defaults to "stage"
	var speed:Float;
	var bpm:Float;
}

typedef ChartNote = {
	var step:Float;
	var index:Int;
	var ?strumline:Int; // defaults to 0 (opponent)
	var ?sustainTime:Float;
	var ?type:String;
}

typedef ChartSection = {
	var camPoint:Int;
	var notes:Array<ChartNote>;
	var ?animation:String; // e.g: "singLEFT-alt"
	var ?length:Int; // in steps
	var ?bpm:Float;
}

typedef FNFSong = {
	var song:String;
	var notes:Array<FNFSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
}

typedef FNFSection = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}
