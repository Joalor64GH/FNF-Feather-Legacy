package game.editors;

import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import game.PlayState;
import game.gameplay.Note;
import game.system.charting.ChartDefs.ChartFormat;
import game.system.charting.ChartLoader;
import game.system.Conductor;
import haxe.Json;

/**
 * State for Editing and Exporting new Charts
 */
class ChartEditor extends MusicBeatState {
	private var const:PlayStateStruct;

	public var song:ChartFormat;
	public var music:MusicPlayback;

	public var renderedNotes:NoteSpriteGroup;
	public var renderedSustains:NoteSpriteGroup;

	public var noteRender:FlxSprite;
	public var noteCamera:FlxObject;

	public function new(const:PlayStateStruct):Void {
		super();
		this.const = const;
		song = ChartLoader.loadChart(const.songName, const.difficulty);
	}

	public var background:FlxSprite;

	public override function create():Void {
		super.create();

		FlxG.mouse.visible = true;

		music = new MusicPlayback(const.songName, const.difficulty);

		background = new FlxSprite().loadGraphic(Paths.image("menus/menuBGMagenta"));
		background.alpha = 0.4;
		add(background);

		// initialize rendering groups
		renderedNotes = new NoteSpriteGroup();
		renderedSustains = new NoteSpriteGroup();
		renderedSections = new FlxTypedGroup<FlxSprite>();

		// create the grid
		generateCheckerboard();
		add(renderedSections);

		// render sustains above notes so it doesn't look weird
		add(renderedSustains);
		add(renderedNotes);

		// camera that objects will follow
		noteCamera = new FlxObject(0, 0, 1, 1);
		noteCamera.centerOverlay(checkerboard, X);

		// note strumline
		noteRender = new FlxSprite().makeGraphic(cellSize * getNoteKeys(), 5, 0xFFFFFFFF);
		noteRender.centerOverlay(checkerboard, X);
		add(noteRender);

		FlxG.camera.follow(noteCamera);
	}

	public var checkerboard:FlxTiledSprite;

	public var cellSize:Int = 50;

	public var renderedSections:FlxTypedGroup<FlxSprite>;

	function generateCheckerboard():Void {
		var checkerSprite:FlxSprite = FlxGridOverlay.create(cellSize, cellSize, cellSize * 2, cellSize * 2, true, 0xFFD8AC9C, 0xFF947566);

		checkerboard = new FlxTiledSprite(null, cellSize * getNoteKeys(), cellSize);
		checkerboard.loadGraphic(checkerSprite.graphic.bitmap);
		checkerboard.screenCenter(X);
		// extend the checkerboard until the song ends, how accurate is this?
		checkerboard.height = (music.inst.length / Conductor.stepCrochet) * cellSize;
		// always add this behind the background
		insert(this.members.indexOf(background), checkerboard);

		generateSection();
	}

	function generateSection():Void {
		for (i in 0...song.sections.length) {
			var sectionLine:FlxText = new FlxText(checkerboard.x + checkerboard.width, 16 * cellSize * i, 0, '${i + 1}');
			sectionLine.setFormat(Paths.font("vcr"), 32);
			renderedSections.add(sectionLine);

			for (note in song.sections[i].notes)
				generateNotes(note.step, note.index, note.sustainTime, note.type, note.strumline);
		}
	}

	public override function update(elapsed:Float):Void {
		Conductor.songPosition = music.inst.time;

		super.update(elapsed);

		noteRender.y = getYfromStrum(Conductor.songPosition);
		noteCamera.y = noteRender.y + (FlxG.height / 2);

		var cameraY:Float = noteCamera.y - (FlxG.height / 2);
		background.y = cameraY;

		if (FlxG.keys.pressed.SHIFT) {
			if (FlxG.keys.justPressed.MINUS || FlxG.keys.justPressed.PLUS) {
				Utils.setVolKeys([], []);

				var nextValue:Int = FlxG.keys.justPressed.MINUS ? -1 : 1;
				song.metadata.strumlines = FlxMath.wrap(song.metadata.strumlines + nextValue, 1, 4);
				regenerateSections();
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
				ChartLoader.noteList = [];

				state = new PlayState({
					songName: const.songName,
					difficulty: const.difficulty,
					songData: song,
					gamemode: CHARTING
				});

				for (i in 0...song.sections.length)
					for (j in song.sections[i].notes)
						ChartLoader.noteList.push(j);
			}

			FlxG.switchState(state);
		}
	}

	public override function stepHit():Void {
		super.stepHit();
		music.resyncFunction();
	}

	function generateNotes(step:Float, index:Int, sustainTime:Float, ?type:String = "default", ?strumline:Int = 0):Void {
		var note:Note = new Note(step, index, false, type, null);
		note.debugging = true;
		note.sustainTime = sustainTime;
		note.strumline = strumline;
		note.setGraphicSize(cellSize, cellSize);
		note.updateHitbox();

		note.centerOverlay(checkerboard, X);
		note.x -= (cellSize * (getNoteKeys() / 2) - (cellSize / 2));
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
				sustain.offset.y = (cellSize) / 2 + 25;
			} else {
				sustain.setGraphicSize(Std.int(cellSize * .35), cellSize + 1);
				sustain.updateHitbox();
				sustain.offset.x = 1;
				sustain.offset.y += 22.5;
			}
		}

		return sustainSprites;
	}

	public function exportChart():Void {
		var json =
			{
				"song": song
			};

		var data:String = Json.stringify(json);
		Utils.saveData('${song.name.toLowerCase()}.json', data);
	}

	function regenerateSections():Void {
		if (checkerboard != null)
			checkerboard.destroy();

		renderedSections.clear();
		renderedSustains.clear();
		renderedNotes.clear();

		// regenerate all sections
		generateCheckerboard();
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

	function getNoteStep(yPos:Float):Float
		return FlxMath.remapToRange(yPos, 0, (music.inst.length / Conductor.stepCrochet) * cellSize, 0, music.inst.length);

	function getYfromStrum(strumTime:Float):Float
		return FlxMath.remapToRange(strumTime, 0, music.inst.length, 0, (music.inst.length / Conductor.stepCrochet) * cellSize);

	function getNoteSide(index:Int, strum:Int):Float {
		var ret:Int = index;
		if (strum > 0) {
			// equation to get correct strumline bs
			for (i in 0...strum)
				ret = (index + 4) % getNoteKeys();
		}

		return ret;
	}

	function getSectionLength():Int
		return song.sections[curSec].length;

	function getNoteKeys():Int {
		var value:Int = 0;
		for (i in 0...song.metadata.strumlines)
			value += 4;
		return value;
	}
}
