package game.gameplay;

import game.system.Conductor;

typedef GradeStatus = {
	var name:String;
	var percent:Int;
}

enum abstract Rating(String) to String {
	var SICK:Rating = 'sick';
	var GOOD:Rating = 'good';
	var BAD:Rating = 'bad';
	var SHIT:Rating = 'shit';
	var MISS:Rating = 'miss';
}

class Highscore {
	// score maps for saving song and week scores
	public static var songScores:Map<String, Int> = [];

	public static function saveScore(song:String, diff:String, score:Int):Void {
		var songName:String = '${song}-${diff}';
		if (songScores.exists(songName)) {
			if (songScores.get(songName) < score)
				songScores.set(songName, score);
		} else
			songScores.set(songName, score);
	}

	public static var weekScores:Map<String, Int> = [];

	public static function saveWeekScore(week:String, diff:String, score:Int):Void {
		var weekName:String = '${week}-${diff}';
		if (weekScores.exists(weekName)) {
			if (weekScores.get(weekName) < score)
				weekScores.set(weekName, score);
		} else
			weekScores.set(weekName, score);
	}

	public static function getScore(song:String, diff:String):Int {
		var songName:String = '${song}-${diff}';
		if (!songScores.exists(song))
			songScores.set(songName, 0);
		return songScores.get(song);
	}

	public static function getWeekScore(week:String, diff:String):Int {
		var weekName:String = '${week}-${diff}';
		if (!weekScores.exists(weekName))
			weekScores.set(weekName, 0);
		return weekScores.get(week);
	}

	// name, score, health, accuracy
	public static var RATINGS:Array<Dynamic> = [
		[SICK, GOOD, BAD, SHIT, MISS], // names
		[350, 250, -50, -100, -250], // score
		[100, 30, -25, -35, -40], // health
		[100, 85, 60, -30, -50] // accuracy
	];

	public var gottenRatings:Map<String, Int> = [];

	// game variables
	public var score:Int = 0;
	public var combo:Int = 0;
	public var health:Float = 1;
	public var misses(get, set):Int;
	public var breaks:Int = 0;

	function get_misses():Int
		return gottenRatings.get("miss");

	function set_misses(missCount:Int):Int {
		gottenRatings.set("miss", missCount);
		return missCount;
	}

	public var notesHit:Int = 0;
	public var notesAccuracy:Float = 0.0001;

	public var accuracy(get, default):Float = 0;

	function get_accuracy():Float
		return notesAccuracy / notesHit;

	public var gradeType:String = "N/A";

	public var grades:Map<String, Int> = [
		"SS" => 100,  "S" => 90, "A" => 80,
		  "B" => 70, "SX" => 69, "C" => 60,
		  "D" => 50,  "E" => 30,  "F" => 0
	];

	public var clearType(get, default):String = "";

	function get_clearType():String {
		var cType:String = ' (${clearType})';
		if (clearType == '' || clearType == null)
			cType = '';
		return cType;
	}

	public var clearFunction:Void->Void;

	public function new():Void {
		// score container bs
		for (i in 0...RATINGS.length)
			gottenRatings.set(RATINGS[0][i], 0);

		clearFunction = function():Void {
			var gottenSicks:Int = gottenRatings.get("sick");
			var gottenGoods:Int = gottenRatings.get("good");
			var gottenBads:Int = gottenRatings.get("bad");
			var gottenShits:Int = gottenRatings.get("shit");

			clearType = "";

			if (misses == 0) {
				if (gottenGoods == 0) {
					if (gottenSicks > 0)
						clearType = 'SFC'; // Sick Full Combo
				} else if (gottenBads == 0 && gottenShits == 0) {
					if (gottenGoods > 0 && gottenGoods < 10)
						clearType = 'SDG'; // Single Digit Goods
					else if (gottenGoods >= 10)
						clearType = 'GFC'; // Good Full Combo
				} else if (gottenBads > 0 || gottenShits > 0) {
					if (gottenBads > 0 && gottenBads < 10)
						clearType = 'SDB'; // Single Digit Bads
					else if (gottenBads >= 10 || gottenShits > 0)
						clearType = 'FC'; // Full Combo
				}
			} else if (misses > 0) {
				if (misses > 0 && misses < 10)
					clearType = 'SDCB'; // Single Digit Combo Breaks
				else if (misses >= 10)
					clearType = 'Clear';
			}
		}

		clearFunction();
	}

	public function judgeNote(stepTime:Float):String {
		var noteDiff:Float = Math.abs(stepTime - Conductor.songPosition);
		var rate:String = SICK;

		if (noteDiff > Conductor.safeZone * 0.9)
			rate = SHIT;
		else if (noteDiff > Conductor.safeZone * 0.75)
			rate = BAD;
		else if (noteDiff > Conductor.safeZone * 0.2)
			rate = GOOD;

		updateRatings(RATINGS[0].indexOf(rate));
		return rate;
	}

	public function updateRatings(rate:Int):Void {
		score += Std.int(RATINGS[1][rate]);
		notesAccuracy += Math.max(0, RATINGS[3][rate]);
		updateGrade();
	}

	public function updateHealth(rate:Int, isSustain:Bool = false):Void {
		var mult:Float = switch (rate) {
			case 3, 4: 0.10;
			default: isSustain ? 0.01 : 0.05;
		}

		health += mult * (RATINGS[2][rate]) / 100;

		if (health > 2)
			health = 2;
		if (health < 0)
			health = 0;
	}

	public function updateGrade():Void {
		var biggestAcc:Int = 0;
		for (grade => acc in grades) {
			if ((acc <= accuracy) && acc >= biggestAcc) {
				biggestAcc = acc;
				gradeType = grade;
			}
		}

		clearFunction();
	}

	public function getPercent():Float {
		if (notesHit > 0)
			return FlxMath.roundDecimal((accuracy * 100) / 100, 2);
		return 0.00;
	}
}
