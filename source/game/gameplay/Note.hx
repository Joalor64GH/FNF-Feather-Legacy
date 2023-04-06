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

	public var arrow:Arrow;
	public var sustain:Sustain;
	public var sustainEnd:FNFSprite;

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
		if (sustain != null)
			sustain.updateHeight();
		return speed;
	}

	public var strumline:Int = 0; // replaced "canBeHit", value for bf is 1
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
		this.type = type;
		this.prevNote = prevNote;
		this.moves = false;

		hitboxEarly = 1;

		/*
			if (sustainTime > 0) {
				//
				this.isSustain = true;
				this.hitboxEarly = 0.5;
				sustain = new Sustain(this);
				sustain.alpha = 0.6;
				add(sustain);
				//
			} else if (isSustain && isEnd) {
				//
				sustainEnd = new FNFSprite(sustain.x, sustain.y + 10);
				sustainEnd.loadFrames('images/notes/${type}/NOTE_assets', [{name: 'idle', prefix: '${Notefield.colors[index]} hold end', framerate: 24}]);
				sustainEnd.playAnim('idle');
				sustainEnd.updateHitbox();
				sustainEnd.flipY = downscroll;
				sustainEnd.alpha = sustain.alpha;
				add(sustainEnd);
				//
			}
		 */

		arrow = new Arrow(this);
		add(arrow);

		if (sustain != null) {
			sustain.x = (arrow.width - sustain.width) / 2;
			sustain.updateHeight();
			if (sustainEnd != null)
				sustainEnd.setPosition(sustain.x, sustain.height - sustain.y);
		}
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!debugging) {
			if (this.strumline == game.playerStrumline) {
				this.canHit = (this.step > Conductor.songPosition - (Conductor.safeZone * this.hitboxEarly)
					&& this.step < Conductor.songPosition + (Conductor.safeZone * this.hitboxLate));
			} else
				this.canHit = false;
		}
	}
}

/**
 * Represents a `Note`'s body
 */
class Arrow extends FNFSprite {
	public var note:Note;

	public function new(_note:Note):Void {
		super();
		note = _note;

		var atlas:FlxAtlasFrames = Paths.getSparrowAtlas('notes/${note.type}/NOTE_assets');
		switch (note.type) {
			default:
				frames = atlas;
				addAnim('${Notefield.colors[note.index]} note', '${Notefield.colors[note.index]}0');
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
		}

		playAnim('${Notefield.colors[note.index]} note');
	}
}

/**
 * Represents a `Note`'s Tail
 */
class Sustain extends FlxTiledSprite {
	public var note:Note;
	public var sustainGraphics:Array<FlxGraphic> = [];

	final noteScale:Float = 0.7;

	public function new(_note:Note):Void {
		super(null, 0, 1);
		note = _note;

		sustainGraphics.resize(4);

		// alright so since TiledSprite requires graphics
		// let's convert frames to graphics
		switch (_note.type) {
			default:
				final atlas:FlxAtlasFrames = Paths.getSparrowAtlas('notes/${_note.type}/NOTE_assets');
				for (prefix in atlas.framesHash.keys()) {
					if (prefix.endsWith('hold piece')) {
						var frame:FlxGraphic = FlxGraphic.fromFrame(atlas.framesHash.get(prefix));
						sustainGraphics.push(frame);
					}
				}
		}

		this.loadGraphic(sustainGraphics[_note.index]);
		// this.width = sustainGraphics[_note.index].width;
		this.scale.set(Std.int(width * noteScale), Std.int(width * noteScale));
		this.antialiasing = Settings.get("antialiasing");
		this.moves = false;
	}

	public function updateHeight():Void {
		var time:Float = Math.floor(note.sustainTime / Conductor.stepCrochet);
		var sustainStep:Float = note.step + (Conductor.stepCrochet * Math.floor(time)) + Conductor.stepCrochet;
		this.height = time;
	}
}

class Splash extends FNFSprite {
	public function new(type:String = "default"):Void {
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
