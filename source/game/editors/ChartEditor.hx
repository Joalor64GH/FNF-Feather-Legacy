package game.editors;

import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import game.PlayState;
import game.gameplay.Note;
import game.system.charting.ChartDefs;
import game.system.charting.ChartLoader;
import game.system.Conductor;

/**
 * State for Editing and Exporting new Charts
 */
class ChartEditor extends MusicBeatState {
	private var const:PlayStateStruct;

	public var song:ChartFormat;
	public var music:MusicPlayback;

	public var renderedNotes:NoteSpriteGroup;
	public var renderedSustains:NoteSpriteGroup;
	public var renderedSections:FlxTypedGroup<FlxSprite>;
	public var renderedLanes:FlxTypedGroup<FlxSprite>;

	public var noteRender:FlxSprite;
	public var noteCamera:FlxObject;

	public function new(const:PlayStateStruct):Void {
		super();
		this.const = const;
		song = ChartLoader.loadChart(const.songName, const.difficulty);
	}

	public override function create():Void {
		super.create();

		FlxG.mouse.visible = true;

		music = new MusicPlayback(const.songName, const.difficulty);

		// initialize rendering groups
		renderedNotes = renderedSustains = new NoteSpriteGroup();
		renderedSections = renderedLanes = new FlxTypedGroup<FlxSprite>();

		// reload all sections
		reloadSections();

		add(renderedLanes);
		add(renderedSections);

		// render sustains above notes so it doesn't look weird
		add(renderedSustains);
		add(renderedNotes);

		// camera that objects will follow
		noteCamera = new FlxObject(0, 0, 1, 1);
		noteCamera.screenCenter(X);

		// note strumline
		noteRender = new FlxSprite().makeGraphic(cellSize * getTotalStrumlines(), 5);
		noteRender.screenCenter(X);
		add(noteRender);

		checkerCursor.makeGraphic(cellSize, cellSize);
		add(checkerCursor);

		FlxG.camera.follow(noteCamera);
	}

	var checkerboard:FlxTiledSprite;
	var checkerCursor:FlxSprite = new FlxSprite();
	var cellSize:Int = 40;

	function generateCheckerboard():Void {
		var checkerBit:openfl.display.BitmapData = FlxGridOverlay.createGrid(cellSize, cellSize, cellSize * 2, cellSize * 2, true, 0xFFD8AC9C, 0xFF947566);

		checkerboard = new FlxTiledSprite(null, cellSize * getTotalStrumlines(), cellSize);
		checkerboard.loadGraphic(checkerBit);
		checkerboard.screenCenter(X);
		// extend the checkerboard until the song ends, how accurate is this?
		checkerboard.height = (music.inst.length / Conductor.stepCrochet) * cellSize;
		add(checkerboard);

		if (song.metadata.strumlines > 1) {
			for (i in 1...song.metadata.strumlines) {
				var separator:FlxSprite = new FlxSprite().makeGraphic(5, Std.int(checkerboard.height), FlxColor.BLACK);
				separator.x = checkerboard.x + cellSize * (4 * i);
				renderedLanes.add(separator);
			}
		}
	}

	function generateSection():Void {
		for (i in 0...song.sections.length) {
			var sectionLine:FlxText = new FlxText(checkerboard.x + checkerboard.width, 16 * cellSize * i, 0, '${i + 1}');
			sectionLine.setFormat(Paths.font("vcr"), 32);
			renderedSections.add(sectionLine);
		}
	}

	public override function update(elapsed:Float):Void {
		Conductor.songPosition = music.inst.time;

		super.update(elapsed);

		noteRender.y = getYfromStrum(Conductor.songPosition);
		noteCamera.y = noteRender.y + (FlxG.height / 2);

		checkerCursor.visible = FlxG.mouse.overlaps(checkerboard);

		if (FlxG.mouse.x > checkerboard.x
			&& FlxG.mouse.x < checkerboard.x + checkerboard.width
			&& FlxG.mouse.y > checkerboard.y
			&& FlxG.mouse.y < checkerboard.y + getYfromStrum(music.inst.length)) {
			checkerCursor.x = Math.floor(FlxG.mouse.x / cellSize) * cellSize;
			if (FlxG.keys.pressed.SHIFT)
				checkerCursor.y = FlxG.mouse.y;
			else
				checkerCursor.y = Math.floor(FlxG.mouse.y / cellSize) * cellSize;

			if (FlxG.mouse.justPressed) {
				if (FlxG.mouse.overlaps(renderedNotes)) {
					renderedNotes.forEach(function(note:Note) {
						if (FlxG.mouse.overlaps(note)) {
							if (!FlxG.keys.pressed.CONTROL)
								deleteNote(note);
						}
					});
				} else {
					if (FlxG.mouse.overlaps(checkerboard))
						addNote();
				}
			}
		}

		if (FlxG.keys.pressed.SHIFT) {
			if (FlxG.keys.justPressed.MINUS || FlxG.keys.justPressed.PLUS) {
				Utils.setVolKeys([], []);

				var nextValue:Int = FlxG.keys.justPressed.MINUS ? -1 : 1;
				song.metadata.strumlines = FlxMath.wrap(song.metadata.strumlines + nextValue, 1, 4);
				reloadSections();
			} else // reset
				Utils.setVolKeys();
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			exportChart();

		if (FlxG.keys.justPressed.SPACE) {
			if (!music.inst.playing)
				music.play();
			else
				music.pause();
		}

		if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE) {
			FlxG.mouse.visible = false;

			var state:flixel.FlxState = new game.menus.FreeplayMenu();
			if (FlxG.keys.justPressed.ESCAPE) {
				state = new PlayState({
					songName: const.songName,
					difficulty: const.difficulty,
					songData: song,
					gamemode: CHARTING
				});

				ChartLoader.fillRawList(song);
			}

			FlxG.switchState(state);
		}
	}

	public override function onStep():Void {
		super.onStep();
		music.resyncFunction();
	}

	function reloadSections():Void {
		if (checkerboard != null) {
			checkerboard.destroy();
			remove(checkerboard);
		}

		var renderingGroups:Array<Dynamic> = [renderedSections, renderedLanes];
		for (renderGroup in renderingGroups)
			renderGroup.clear();

		// regenerate all sections
		generateCheckerboard();
		generateSection();

		// regenerate notes

		reloadNotes();
	}

	function reloadNotes(clearBefore:Bool = true):Void {
		if (clearBefore) {
			var renderingGroups:Array<Dynamic> = [renderedNotes, renderedSustains];
			for (renderGroup in renderingGroups)
				renderGroup.clear();
		}

		for (i in 0...song.sections.length)
			for (note in song.sections[i].notes)
				generateNotes(note.step, note.index, note.sustainTime, note.type, note.strumline);
	}

	function generateNotes(step:Float, index:Int, sustainTime:Float, ?type:String = "default", ?strumline:Int = 0):Void {
		var note:Note = new Note(step, index, false, type, null);
		note.debugging = true;
		note.sustainTime = sustainTime;
		note.strumline = strumline;
		note.setGraphicSize(cellSize, cellSize);
		note.updateHitbox();
		note.screenCenter(X);

		// center
		note.x -= cellSize * (getTotalStrumlines() / 2) - (cellSize / 2);
		note.x += Math.floor(getNoteSide(index, strumline) * cellSize);
		note.y = Math.floor(getYfromStrum(step));

		renderedNotes.add(note);

		if (note.sustainTime > 0)
			for (sustain in generateSustainNote(Conductor.stepCrochet, note))
				renderedSustains.add(sustain);
	}

	function generateSustainNote(step:Float, note:Note):Array<Note> {
		var length:Int = Math.floor(note.sustainTime / step);
		if (length < 1)
			length = 1;

		var sustainSprites:Array<Note> = [];
		var previous:Note = note;

		for (i in 0...length + 1) {
			var sustain:Note = new Note(note.step + (step * i) + step, note.index % 4, true, note.type, previous);
			sustain.debugging = true;
			sustain.setPosition(note.x, previous.y + cellSize);
			sustain.flipY = false;

			// update size
			sustain.setGraphicSize(Std.int(cellSize / 3), Std.int(cellSize / 3));
			sustain.updateHitbox();
			sustain.scale.y = 1;
			previous = sustain;
			sustainSprites.push(sustain);
		}

		for (sustain in sustainSprites) {
			if (sustain.animation.curAnim != null && sustain.animation.curAnim.name.endsWith('end')) {
				sustain.setGraphicSize(Std.int(cellSize * .35), Std.int((cellSize) / 2));
				sustain.updateHitbox();
				sustain.offset.x = 1;
				sustain.offset.y += (cellSize) / 2 + 25;
			} else {
				sustain.setGraphicSize(Std.int(cellSize * .35), cellSize + 1);
				sustain.updateHitbox();
				sustain.offset.x = 1;
				sustain.offset.y = 25;
			}
		}

		return sustainSprites;
	}

	public function exportChart():Void {
		var json = {"song": song};
		var data:String = tjson.TJSON.encode(json);
		Utils.saveData('${song.name.toLowerCase()}.json', data);
	}

	function addNote(pushNext:Bool = true):Void {
		var stepTime:Float = getNoteStep(checkerCursor.y);
		var stepSection:Int = Math.floor(stepTime / (Conductor.stepCrochet * 16));
		var sustainLength:Float = 0;

		for (i in 0...song.sections[curSec].notes.length) {
			var note:ChartNote = song.sections[curSec].notes[i];
			var currentIndex:Int = getNoteSide(Math.floor((checkerCursor.x - checkerboard.x) / cellSize), note.strumline);

			if (pushNext) {
				song.sections[stepSection].notes.push({step: stepTime, index: currentIndex, sustainTime: sustainLength});
				// curSelectedNote = song.sections[curSec].notes[song.sections[stepSection].notes.length - 1];
			}

			if (FlxG.keys.pressed.CONTROL) {
				song.sections[curSec].notes.push({
					step: stepTime,
					index: getNoteSide(currentIndex, note.strumline),
					sustainTime: sustainLength
				});
			}

			FlxG.log.add('added note ${note.index} at ${note.step}');
		}

		reloadSections();
	}

	function deleteNote(note:Note):Void {
		for (i in 0...song.sections.length) {
			for (secNote in song.sections[i].notes) {
				if (note.strumline != secNote.strumline)
					note.index += 4;

				if (secNote.step == note.step && secNote.index == note.index) {
					FlxG.log.add('deleted note ${note.index} at ${note.step}');
					song.sections[curSec].notes.remove(secNote);
					break;
				}
			}
		}

		reloadSections();
	}

	function getSectionStart():Float {
		var daBPM:Float = song.metadata.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec) {
			if (song.sections[i].bpm != daBPM)
				daBPM = song.sections[i].bpm;
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	function getNoteStep(yPos:Float):Float {
		return FlxMath.remapToRange(yPos, 0, (music.inst.length / Conductor.stepCrochet) * cellSize, 0, music.inst.length);
		// return FlxMath.remapToRange(yPos, checkerboard.y, checkerboard.y + checkerboard.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(stepTime:Float):Float
		return FlxMath.remapToRange(stepTime, 0, music.inst.length, 0, (music.inst.length / Conductor.stepCrochet) * cellSize);

	function getNoteSide(index:Int, strum:Int):Int {
		var ret:Int = index;

		if (strum > 0)
			for (i in 0...strum) // equation to get correct strumline bs
				ret = (index + 4) % getTotalStrumlines();
		return ret;
	}

	function getTotalStrumlines():Int {
		var value:Int = 0;
		for (i in 0...song.metadata.strumlines)
			value += 4;
		return value;
	}
}
