package feather.gameObjs;

import feather.core.FNFSprite;
import feather.core.music.Conductor;
import feather.state.PlayState;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;

class Note extends FNFSprite {
	final game:PlayState = PlayState.self;

	public var prevNote:Note = null;
	public var debugging:Bool = false;

	public var index:Int = 0;
	public var type:String = "default";

	// note type parameters
	public var isMine:Bool = false;
	public var ignorable:Bool = false;
	public var doSplash:Bool = true;
	public var killDelay:Int = 200;

	public var stepTime:Float = 0.0;
	public var stepSustain:Float = 0.0;
	public var noteSpeed(default, set):Float = 1.0;

	function set_noteSpeed(newSpeed:Float):Float {
		if (noteSpeed != newSpeed) {
			noteSpeed = newSpeed;
			updateSustain();
		}
		return noteSpeed;
	}

	public var strumline:Int = 0;
	public var canHit:Bool = false;
	public var mustHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var wasTooLate:Bool = false;

	public var isSustain:Bool = false;
	public var isEnd:Bool = false;

	public var downscroll:Bool = false;

	public var hitboxEarly:Float = 1;
	public var hitboxLate:Float = 1;

	public var parent:Note;
	public var children:Array<Note> = [];

	public var offX:Float = 0;
	public var offY:Float = 0;

	final noteBeatCrochet:Float = Conductor.beatCrochet;
	final noteStepCrochet:Float = Conductor.stepCrochet;

	public function new(stepTime:Float, index:Int, ?stepSustain:Float, ?type:String = "default", ?prevNote:Note):Void {
		super(0, -2000);

		if (prevNote == null)
			prevNote = this;

		this.stepTime = stepTime;
		this.index = index;
		this.stepSustain = stepSustain;
		this.type = type;
		this.prevNote = prevNote;

		if (this.stepSustain > 0)
			this.isSustain = true;

		hitboxEarly = 1;

		loadFrames('images/notes/${type}/NOTE_assets', [
			{name: '${Notefield.colors[index]}Scroll', prefix: '${Notefield.colors[index]}0'},
			{name: '${Notefield.colors[index]}Hold', prefix: '${Notefield.colors[index]} hold piece'},
			{name: '${Notefield.colors[index]}End', prefix: '${Notefield.colors[index]} hold end'}
		]);
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		playAnim('${Notefield.colors[index]}Scroll');

		if (isSustain && prevNote != null) {
			hitboxEarly = 0.5;
			parent = prevNote;
			// oh, my god.
			while (parent.parent != null)
				parent = parent.parent;
			children.push(this);
		} else if (!isSustain)
			parent = null;

		antialiasing = UserSettings.get("antialiasing");
		moves = false;
	}

	public function updateSustain():Void {
		if (isSustain) {
			alpha = 0.6;
			flipX = downscroll;
			playAnim('${Notefield.colors[index]}End');

			if (prevNote != null && prevNote.exists) {
				playAnim('${Notefield.colors[index]}Hold');
				if (prevNote.isSustain) {
					prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * noteStepCrochet / 50 * 1.05 * noteSpeed;
					prevNote.updateHitbox();
					offX = prevNote.x;
				} else
					offX = ((prevNote.width / 2) - (width / 2));
			}
		}
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!debugging) {
			if (mustHit) {
				canHit = (stepTime > Conductor.songPosition - (Conductor.safeZone * hitboxEarly)
					&& stepTime < Conductor.songPosition + (Conductor.safeZone * hitboxLate));
			} else
				canHit = false;

			if (wasTooLate || (parent != null && parent.wasTooLate))
				alpha = 0.3;
		}
	}
}

class Splash extends FNFSprite {
	public function new(index:Int, type:String = "default"):Void {
		super(0, 0);
		loadFrames('images/notes/${type}/NOTE_splashes');
		for (n in 0...2)
			for (i in 0...Notefield.colors.length)
				addAnim('impact ${Notefield.colors[i]}${n}', '${Notefield.colors[i]} splash ${n}', null, 24);
		moves = false;
	}

	public override function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
		super.playAnim(name, force, reversed, frame);
		centerOrigin();
		centerOffsets();
	}
}
