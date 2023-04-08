package game.gameplay;

import core.FNFSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import game.PlayState;
import game.system.Conductor;

class Note extends FlxSpriteGroup {
	final game:PlayState = PlayState.self;

	public var arrow:NoteObj;
	public var sustain:SustainObj;

	public var prevNote:Note = null;
	public var debugging:Bool = false;

	public var index:Int = 0;
	public var type:String = "default";

	// note type parameters
	public var isMine:Bool = false;
	public var ignorable:Bool = false;
	public var doSplash:Bool = true;
	public var killDelay:Int = 200;

	public var step:Float = 0.0;
	public var sustainTime:Float = 0.0;
	public var speed(default, set):Float = 1.0;

	function set_speed(newSpeed:Float):Float {
		if (speed != newSpeed)
			speed = newSpeed;
		if (sustain != null) {
			sustain.centerOverlay(arrow, X);
			sustain.height = sustainTime;
		}
		return speed;
	}

	public var strumline:Int = 0;
	public var mustHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var canHit:Bool = false;

	public var isSustain:Bool = false;
	public var isEnd:Bool = false;

	public var downscroll:Bool = false;

	public var hitboxEarly:Float = 1;
	public var hitboxLate:Float = 1;

	public function new(step:Float, index:Int, ?sustainTime:Float, ?type:String = "default", ?prevNote:Note):Void {
		super(0, -2000);

		if (prevNote == null)
			prevNote = this;

		this.step = step;
		this.index = index;
		this.sustainTime = sustainTime;
		if (sustainTime > 0)
			this.isSustain = true;
		this.type = type;
		this.prevNote = prevNote;
		this.moves = false;

		hitboxEarly = 1;

		arrow = new NoteObj(this);
		add(arrow);

		if (isSustain) {
			hitboxEarly = 0.5;
			sustain = new SustainObj(this);
			sustain.centerOverlay(arrow, X);
			add(sustain);
		}
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!debugging) {
			if (mustHit) {
				canHit = (step > Conductor.songPosition - (Conductor.safeZone * hitboxEarly)
					&& step < Conductor.songPosition + (Conductor.safeZone * hitboxLate));
			} else
				canHit = false;
		}
	}
}

class NoteObj extends FNFSprite {
	public var note:Note;

	public function new(_note:Note):Void {
		super();

		note = _note;

		loadFrames('images/notes/${_note.type}/NOTE_assets', [
			{name: '${Notefield.colors[_note.index]} note', prefix: '${Notefield.colors[_note.index]}0'}
		]);
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		playAnim('${Notefield.colors[_note.index]} note');
	}
}

class SustainObj extends FlxTiledSprite {
	public var note:Note;
	public var framesStored:Array<FlxFrame> = [];

	public function new(_note:Note):Void {
		super(null, 0, 1);

		note = _note;

		final atlas:FlxAtlasFrames = Paths.getSparrowAtlas('notes/${_note.type}/NOTE_assets');
		for (prefix in atlas.framesHash.keys())
			if (prefix.endsWith('hold piece0000'))
				framesStored.push(atlas.framesHash.get(prefix));

		loadFrame(framesStored[_note.index]);
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}
}

class Splash extends FNFSprite {
	public function new(index:Int, type:String = "default"):Void {
		super(0, 0);
		this.loadFrames('images/notes/${type}/NOTE_splashes');
		for (n in 0...2)
			for (i in 0...Notefield.colors.length)
				this.addAnim('impact ${Notefield.colors[i]}${n}', '${Notefield.colors[i]} splash ${n}', null, 24);
		this.moves = false;
	}

	public override function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
		super.playAnim(name, force, reversed, frame);
		centerOrigin();
		centerOffsets();
	}
}
