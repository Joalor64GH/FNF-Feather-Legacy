package game;

import game.gameplay.Note;
import game.gameplay.Notefield;
import game.system.Conductor;
import game.system.ChartDefs;
import game.system.ChartLoader;
import flixel.group.FlxGroup.FlxTypedGroup;

class NoteRenderTest extends MusicBeatState {
	var song:ChartFormat;
	var music:MusicPlayback;

	var songName:String = 'milf';
	var difficulty:String = 'hard';

	var localNoteStorage:Array<Note> = [];
	var noteFields:FlxTypedGroup<Notefield>;
	var playerNotefield(get, never):Notefield;

	@:keep inline function get_playerNotefield():Notefield
		return noteFields.members[1];

	var starting:Bool = true;

	public function new():Void {
		super();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		song = ChartLoader.loadSong(songName, difficulty);
	}

	public override function create():Void {
		super.create();

		ChartLoader.fillUnspawnList();

		music = new MusicPlayback(songName, difficulty);

		noteFields = new FlxTypedGroup<Notefield>();
		add(noteFields);

		for (i in 0...2) {
			var isPlayer:Bool = i == 1;
			var spacing:Float = 160 * 0.7;

			var strumInitDist:Float = FlxG.width / 10;
			var strumDistance:Float = FlxG.width / 2 * i;
			if (isPlayer && UserSettings.get("centerScroll")) {
				strumInitDist = FlxG.width / 4;
				strumDistance = 115;
			}

			var xPos:Float = (strumInitDist) + strumDistance;
			var yPos:Float = UserSettings.get("scrollType") == "DOWN" ? FlxG.height - 150 : 60;
			if (i == 0)
				xPos -= 60;

			var newField:Notefield = new Notefield(xPos, yPos, null, spacing);
			newField.cpuControlled = !isPlayer;
			if (UserSettings.get("centerScroll"))
				newField.visible = isPlayer;
			newField.ID = i;
			noteFields.add(newField);
		}

		// preload notes
		for (i in ChartLoader.unspawnNoteList) {
			i.mustHit = i.strumline == 1;
			localNoteStorage.push(i);
		}

		controls.onKeyPressed.add(onKeyPress);
		controls.onKeyReleased.add(onKeyRelease);
	}

	public override function update(elapsed:Float):Void {
		if (song == null)
			return;

		if (starting) {
			Conductor.songPosition += FlxG.elapsed * 1000;
			if (Conductor.songPosition >= 0) {
				starting = false;
				music.play();
			}
		} else
			Conductor.songPosition = music.inst.time;

		super.update(elapsed);

		for (strum in noteFields) {
			while (localNoteStorage != null && localNoteStorage.length > 0) {
				var unspawnNote:Note = localNoteStorage[0];
				var strum:Notefield = noteFields.members[unspawnNote.strumline];
				if (unspawnNote.step - Conductor.songPosition > 2000)
					break;

				if (strum.ID == unspawnNote.strumline)
					strum.add(unspawnNote);

				localNoteStorage.splice(localNoteStorage.indexOf(unspawnNote), 1);
			}

			strum.noteObjects.forEachAlive(function(note:Note):Void {
				note.speed = Math.abs(song.speed);

				if (strum.cpuControlled) {
					if (!note.wasGoodHit && note.step <= Conductor.songPosition)
						goodNoteHit(note, strum);
				} // sustain note inputs
				else if (!playerNotefield.cpuControlled) {
					if (notesPressed[note.index] && (note.isSustain && note.canHit && note.strumline == 1))
						goodNoteHit(note, playerNotefield);
				}

				var rangeReached:Bool = note.downscroll ? note.arrow.y > FlxG.height : note.arrow.y < -note.arrow.height;
				var sustainHit:Bool = note.isSustain && note.wasGoodHit && note.step <= Conductor.songPosition - note.hitboxEarly;

				if (Conductor.songPosition > note.killDelay + note.step) {
					if (rangeReached || sustainHit) {
						if (rangeReached && !note.wasGoodHit && !note.ignorable && !note.isMine)
							if (note.strumline == 1)
								noteMiss(note.index, strum);
						strum.remove(note, true);
					}
				}
			});
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new game.menus.MainMenu());

		if (playerNotefield != null && FlxG.keys.justPressed.SIX)
			playerNotefield.cpuControlled = !playerNotefield.cpuControlled;
	}

	var notesPressed:Array<Bool> = [];

	public function onKeyPress(key:Int, action:String):Void {
		if (playerNotefield == null || playerNotefield.cpuControlled)
			return;

		if (action != null && Notefield.directions.contains(action)) {
			var index:Int = Notefield.directions.indexOf(action);
			notesPressed[index] = true;

			var dumbNotes:Array<Note> = [];
			var possibleNotes:Array<Note> = [];

			playerNotefield.noteObjects.forEachAlive(function(note:Note):Void {
				if (note.canHit && note.strumline == 1 && !note.wasGoodHit) {
					if (note.index == index)
						possibleNotes.push(note);
				}
			});
			possibleNotes.sort((a:Note, b:Note) -> flixel.util.FlxSort.byValues(flixel.util.FlxSort.ASCENDING, a.step, b.step));

			if (possibleNotes.length > 0) {
				var canBeHit:Bool = true;
				for (note in possibleNotes) {
					for (dumbNote in dumbNotes) {
						// "dumb" notes are doubles
						if (Math.abs(note.step - dumbNote.step) < 10)
							playerNotefield.remove(dumbNote, true);
						else
							canBeHit = false;
					}

					if (canBeHit) {
						goodNoteHit(note, playerNotefield);
						dumbNotes.push(note);
					}
				}
			} else {
				if (!UserSettings.get("ghostTapping"))
					noteMiss(index, playerNotefield);
			}

			if (!playerNotefield.currentAnim('confirm', Notefield.directions.indexOf(action)))
				playerNotefield.playAnim('pressed', Notefield.directions.indexOf(action));
		}
	}

	function goodNoteHit(note:Note, strum:Notefield):Void {
		if (!note.wasGoodHit) {
			note.wasGoodHit = true;
			strum.playAnim('confirm', note.index, true);

			if (music.vocals != null && music.vocals.playing)
				music.vocals.volume = 1;

			if (!note.isSustain)
				strum.remove(note, true);
		}
	}

	function noteMiss(direction:Int = 0, ?strum:Notefield, ?showMiss:Bool = true):Void {
		if (music.vocals != null && music.vocals.playing)
			music.vocals.volume = 0;

		FlxG.sound.play(AssetHandler.getAsset('sounds/game/miss' + FlxG.random.int(1, 3), SOUND), FlxG.random.float(0.3, 0.6));
	}

	public function onKeyRelease(key:Int, action:String):Void {
		if (playerNotefield == null || playerNotefield.cpuControlled)
			return;

		if (action != null && Notefield.directions.contains(action)) {
			var index:Int = Notefield.directions.indexOf(action);
			notesPressed[index] = false;
			playerNotefield.playAnim('static', Notefield.directions.indexOf(action));
		}
	}

	public override function destroy():Void {
		controls.onKeyPressed.remove(onKeyPress);
		controls.onKeyReleased.remove(onKeyRelease);
		super.destroy();
	}
}
