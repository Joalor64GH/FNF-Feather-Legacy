package game.editors;

import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import game.PlayState;
import game.gameplay.Note;
import game.gameplay.NoteGroup;
import game.system.charting.ChartDefs.ChartFormat;
import game.system.charting.ChartLoader;
import game.system.music.Conductor;
import haxe.Json;

/**
 * State for Editing and Exporting new Charts
 */
class ChartEditor extends MusicBeatState
{
	private var const:PlayStateStruct;

	public var song:ChartFormat;
	public var music:MusicPlayback;

	public var renderedNotes:NoteSpriteGroup;
	public var renderedHolds:NoteSpriteGroup;

	public var noteRender:FlxSprite;
	public var noteCamera:FlxObject;

	public function new(const:PlayStateStruct):Void
	{
		super();
		this.const = const;
		song = ChartLoader.loadChart(const.songName, const.difficulty);
	}

	public var background:FlxSprite;

	public override function create():Void
	{
		super.create();

		FlxG.mouse.visible = true;

		music = new MusicPlayback(const.songName, const.difficulty);

		background = new FlxSprite().loadGraphic(Paths.image("menus/menuBGMagenta"));
		background.alpha = 0.4;
		add(background);

		// create the grid
		renderedSections = new FlxTypedGroup<FlxSprite>();
		generateCheckerboard();
		add(renderedSections);

		// camera that objects will follow
		noteCamera = new FlxObject(0, 0);
		noteCamera.centerOverlay(checkerboard, X);

		// note strumline
		noteRender = new FlxSprite().makeGraphic(cellSize * keys, 5, 0xFFFFFFFF);
		noteRender.centerOverlay(checkerboard, X);
		add(noteRender);

		FlxG.camera.follow(noteCamera);
	}

	public var checkerboard:FlxTiledSprite;

	public var keys:Int = 8;
	public var cellSize:Int = 50;

	public var renderedSections:FlxTypedGroup<FlxSprite>;

	function generateCheckerboard():Void
	{
		var checkerSprite:FlxSprite = FlxGridOverlay.create(cellSize, cellSize, cellSize * 2, cellSize * 2, true, 0xFFD8AC9C, 0xFF947566);

		checkerboard = new FlxTiledSprite(null, cellSize * keys, cellSize);
		checkerboard.loadGraphic(checkerSprite.graphic.bitmap);
		checkerboard.screenCenter(X);
		// extend the checkerboard until the song ends, how accurate is this?
		checkerboard.height = (music.inst.length / Conductor.stepCrochet) * cellSize;
		add(checkerboard);

		generateSectionLines();
	}

	function generateSectionLines():Void
	{
		for (i in 0...song.sections.length)
		{
			var sectionLine:FlxText = new FlxText(checkerboard.x + checkerboard.width, 16 * cellSize * i, 0, '${i}');
			sectionLine.setFormat(Paths.font("vcr"), 32);
			renderedSections.add(sectionLine);
		}
	}

	public override function update(elapsed:Float):Void
	{
		Conductor.songPosition = music.inst.time;

		super.update(elapsed);

		noteRender.y = getYfromStrum(Conductor.songPosition);
		noteCamera.y = noteRender.y + (FlxG.height / 2);

		var cameraY:Float = noteCamera.y - (FlxG.height / 2);
		background.y = cameraY;

		if (FlxG.keys.justPressed.SPACE)
		{
			if (!music.inst.playing)
				music.play();
			else
				music.pause();
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(new PlayState({songName: const.songName, difficulty: const.difficulty, gamemode: CHARTING}));
		}
	}

	public override function stepHit():Void
	{
		super.stepHit();
		music.resyncFunction();
	}

	public function exportChart():Void
	{
		var json = {
			"song": song
		};

		var data:String = Json.stringify(json);
		Utils.saveData('${song.name.toLowerCase()}.json', data);
	}

	function getSectionStart():Float
	{
		var daBPM:Float = song.metadata.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec)
		{
			if (song.sections[i].bpm != daBPM)
				daBPM = song.sections[i].bpm;
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	function getNoteStep(yPos:Float):Float
		return FlxMath.remapToRange(yPos, 0, (music.inst.length / Conductor.stepCrochet) * cellSize, 0, music.inst.length);

	function getYfromStrum(step:Float):Float
		return FlxMath.remapToRange(step, 0, music.inst.length, 0, (music.inst.length / Conductor.stepCrochet) * cellSize);

	function getNoteSide(index:Int, mustHit:Bool):Void
		return (mustHit ? ((index + 4) % 8) : index);

	function getSectionLength():Int
		return song.sections[curSec].length;
}
