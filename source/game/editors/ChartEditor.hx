package game.editors;

import core.FNFSprite;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxGradient;
import game.PlayState;
import game.gameplay.Note;
import game.system.charting.ChartDefs;
import game.system.charting.ChartLoader;
import game.system.Conductor;
import openfl.geom.ColorTransform;

/**
 * State for Editing and Exporting new Charts
 */
class ChartEditor extends MusicBeatState {
	private var const:PlayStateStruct;

	public var song:ChartFormat;
	public var music:MusicPlayback;

	public var sideBar:FlxSprite;
	public var infoText:FlxText;

	public var renderedNotes:FlxTypedGroup<FNFSprite>;
	public var renderedSustains:FlxTypedGroup<FlxTiledSprite>;
	public var renderedSections:FlxTypedGroup<FlxSprite>;
	public var renderedLanes:FlxTypedGroup<FlxSprite>;

	public var crochetObject:FlxSprite;
	public var cameraObject:FlxObject;

	public function new(const:PlayStateStruct):Void {
		super();
		this.const = const;

		song = ChartLoader.loadChart(const.songName, const.difficulty);
	}

	public override function create():Void {
		super.create();

		FlxG.mouse.visible = true;
		music = new MusicPlayback(const.songName, const.difficulty);
		generateBackground();

		// initialize rendering groups
		renderedNotes = new FlxTypedGroup<FNFSprite>();
		renderedSustains = new FlxTypedGroup<FlxTiledSprite>();
		renderedSections = new FlxTypedGroup<FlxSprite>();
		renderedLanes = new FlxTypedGroup<FlxSprite>();

		// reload all sections
		reloadSections();

		add(renderedLanes);
		add(renderedSections);

		// render sustains above notes so it doesn't look weird
		add(renderedSustains);
		add(renderedNotes);

		// note strumline
		crochetObject = new FlxSprite().makeGraphic(cellSize * getTotalStrumlines(), 5);
		crochetObject.screenCenter(X);
		add(crochetObject);

		checkerCursor.makeGraphic(cellSize, cellSize);
		add(checkerCursor);

		loadUI();

		// camera that objects will follow
		cameraObject = new FlxObject(0, 0, 1, 1);
		FlxG.camera.follow(cameraObject, LOCKON);
	}

	var noteBG:FlxBackdrop;
	var darkGradient:FlxSprite;

	function generateBackground():Void {
		#if (flixel_addons <= "2.12.1")
		noteBG = new FlxBackdrop(null, 1, 1, true, false);
		#else
		noteBG = new FlxBackdrop(null, XY, 1, 1);
		#end
		noteBG.loadGraphic(Paths.image('menus/chart/grid'));
		noteBG.scrollFactor.set();
		noteBG.screenCenter();
		noteBG.alpha = 0;
		add(noteBG);

		darkGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF000000, 0xFFFFFFFF]);
		darkGradient.scrollFactor.set();
		darkGradient.alpha = 0;
		add(darkGradient);

		FlxTween.tween(noteBG, {alpha: 60 / 255}, 0.8, {ease: FlxEase.cubeOut});
		FlxTween.tween(darkGradient, {alpha: 30 / 255}, 0.6, {ease: FlxEase.cubeOut});
	}

	var checkerboard:FlxTiledSprite;
	var checkerCursor:FlxSprite = new FlxSprite();
	var cellSize:Int = 40;

	function generateCheckerboard():Void {
		var checkerBit:openfl.display.BitmapData = FlxGridOverlay.createGrid(cellSize, cellSize, cellSize * 2, cellSize * 2, true, 0xFF9AB671, 0xFF549235);
		checkerBit.colorTransform(checkerBit.rect, new ColorTransform(1, 1, 1, 90 / 255));

		checkerboard = new FlxTiledSprite(null, cellSize * getTotalStrumlines(), cellSize);
		checkerboard.loadGraphic(checkerBit);
		checkerboard.screenCenter(X);
		// extend the checkerboard until the song ends, how accurate is this?
		checkerboard.height = (music.inst.length / Conductor.stepCrochet) * cellSize;
		add(checkerboard);

		for (i in 1...2) {
			var separator:FlxSprite = new FlxSprite().makeGraphic(5, Std.int(checkerboard.height), FlxColor.BLACK);
			separator.x = checkerboard.x + cellSize * (4 * i);
			renderedLanes.add(separator);
		}
	}

	function generateSection():Void {
		for (i in 0...song.sections.length) {
			var sectionLine:FlxText = new FlxText(checkerboard.x + checkerboard.width, 16 * cellSize * i, 0, '${i + 1}');
			sectionLine.setFormat(Paths.font("vcr"), 32);
			renderedSections.add(sectionLine);
		}
	}

	function loadUI():Void {
		infoText = new FlxText(0, 0, 0, getInfoText());
		infoText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 20, 0xFFFFFFFF, OUTLINE);
		infoText.setPosition(5, FlxG.height - infoText.height - 5);
		infoText.scrollFactor.set();
		infoText.alpha = 0;
		add(infoText);

		FlxTween.tween(infoText, {alpha: 1}, 0.8, {ease: FlxEase.cubeOut});
	}

	function getInfoText():String {
		var curBPM:Float = song.metadata.bpm;
		if (song.sections[curSec] != null) {
			if (song.sections[curSec].bpm != null && song.sections[curSec].bpm != curBPM)
				curBPM = song.sections[curSec].bpm;
		}

		return '${song.name} - BPM: ${curBPM}\nBEAT: ${curBeat} - STEP: ${curStep} - BAR: ${curSec + 1}';
	}

	public override function update(elapsed:Float):Void {
		Conductor.songPosition = music.inst.time;

		super.update(elapsed);

		crochetObject.y = getYFromStep(Conductor.songPosition);
		cameraObject.screenCenter(X);
		cameraObject.y = crochetObject.y + (FlxG.height / 2);

		checkerCursor.visible = FlxG.mouse.overlaps(checkerboard);

		if (FlxG.mouse.x > checkerboard.x
			&& FlxG.mouse.x < checkerboard.x + checkerboard.width
			&& FlxG.mouse.y > checkerboard.y
			&& FlxG.mouse.y < checkerboard.y + getYFromStep(music.inst.length)) {
			checkerCursor.x = Math.floor(FlxG.mouse.x / cellSize) * cellSize;
			if (FlxG.keys.pressed.SHIFT)
				checkerCursor.y = FlxG.mouse.y;
			else
				checkerCursor.y = Math.floor(FlxG.mouse.y / cellSize) * cellSize;

			if (FlxG.mouse.justPressed) {
				if (FlxG.mouse.overlaps(renderedNotes)) {
					renderedNotes.forEach(function(note:FNFSprite) {
						if (FlxG.mouse.overlaps(note)) {
							if (!FlxG.keys.pressed.CONTROL) {}
						}
					});
				} else {
					if (FlxG.mouse.overlaps(checkerboard))
						addNote();
				}
			}
		}

		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT) {
			var nextValue:Int = FlxG.keys.justPressed.LEFT ? -1 : 1;
			beatContainer.secPos = FlxMath.wrap(curSec + nextValue, 0, song.sections.length - 1);
			beatContainer.update(elapsed);
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

		infoText.text = getInfoText();
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
		var noteBase:Note = new Note(step, index % 4, 0, type, null);
		noteBase.debugging = true;
		noteBase.sustainTime = sustainTime;
		noteBase.strumline = strumline;

		var note:FNFSprite = noteBase.arrow;
		note.setGraphicSize(cellSize, cellSize);
		note.updateHitbox();
		note.screenCenter(X);

		// center
		note.x -= cellSize * (getTotalStrumlines() / 2) - (cellSize / 2);
		note.x += Math.floor(getNoteSide(index, strumline) * cellSize);
		note.y = Math.floor(getYFromStep(step));
		renderedNotes.add(note);

		/*
			if (note.sustainTime > 0)
				for (sustain in generateSustainNote(Conductor.stepCrochet, note))
					renderedSustains.add(sustain);
		 */
	}

	function generateSustainNote(step:Float, note:Note):Array<Note> {
		var length:Int = Math.floor(note.sustainTime / step);
		if (length < 1)
			length = 1;

		var sustainSprites:Array<Note> = [];
		var previous:Note = note;

		for (i in 0...length + 1) {
			var sustain:Note = new Note(note.step + (step * i) + step, note.index % 4, note.sustainTime, note.type, previous);
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

	@:keep inline function getSectionStart():Float {
		var daBPM:Float = song.metadata.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec) {
			if (song.sections[i].bpm != daBPM)
				daBPM = song.sections[i].bpm;
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	@:keep inline function getNoteStep(yPos:Float):Float
		return FlxMath.remapToRange(yPos, 0, (music.inst.length / Conductor.stepCrochet) * cellSize, 0, music.inst.length);

	@:keep inline function getYFromStep(stepTime:Float):Float
		return FlxMath.remapToRange(stepTime, 0, music.inst.length, 0, (music.inst.length / Conductor.stepCrochet) * cellSize);

	@:keep inline function getNoteSide(index:Int, strum:Int):Int {
		var ret:Int = index;
		if (strum > 0)
			for (i in 0...strum) // equation to get correct strumline bs
				ret = (index + 4) % getTotalStrumlines();
		return ret;
	}

	@:keep inline function getTotalStrumlines():Int {
		var value:Int = 0;
		for (i in 0...2)
			value += 4;
		return value;
	}

	@:keep inline function exportChart():Void {
		var json = {"song": song};
		var data:String = tjson.TJSON.encode(json);
		Utils.saveData('${song.name.toLowerCase()}.json', data);
	}
}
