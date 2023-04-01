package game.gameplay;

import core.FNFSprite;
import game.PlayState;
import game.system.Conductor;

typedef NoteSpriteGroup = flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<Note>;

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

	public var step:Float = 0.0;
	public var sustainTime:Float = 0.0;
	public var speed(default, set):Float = 1.0;

	function set_speed(newSpeed:Float):Float {
		if (speed != newSpeed) {
			speed = newSpeed;
			updateSustain();
		}
		return speed;
	}

	public var strumline:Int = 0; // replaced "canBeHit", value for bf is 1
	public var wasGoodHit:Bool = false;
	public var canHit:Bool = false;

	public var isSustain:Bool = false;
	public var isEnd:Bool = false;

	public var downscroll:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var hitboxEarly:Float = 1;
	public var hitboxLate:Float = 1;

	public function new(step:Float, index:Int, ?isSustain:Bool, ?type:String = "default", ?prevNote:Note):Void {
		super(0, -2000);

		if (prevNote == null)
			prevNote = this;

		this.step = step;
		this.index = index;
		this.isSustain = isSustain;
		this.type = type;
		this.prevNote = prevNote;
		this.moves = false;

		frames = AssetHandler.getAsset('images/notes/${type}/NOTE_assets', XML);
		addAnim('${NoteGroup.colors[index]} note', '${NoteGroup.colors[index]}0');
		addAnim('${NoteGroup.colors[index]} end', '${NoteGroup.colors[index]} hold end');
		addAnim('${NoteGroup.colors[index]} hold', '${NoteGroup.colors[index]} hold piece');
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		antialiasing = Settings.get("antialiasing");

		if (!isSustain) {
			hitboxEarly = 1;
			playAnim('${NoteGroup.colors[index]} note');
		} else
			updateSustain();
	}

	/**
	 * Don't break on bpm changes Don't break on bpm changes Don't break on bpm changes Don't break on bpm changes
	 */
	final noteStepCrochet:Float = Conductor.stepCrochet;

	public function updateSustain():Void {
		if (isSustain) {
			flipY = downscroll;
			hitboxEarly = 0.5;
			alpha = 0.6;

			playAnim('${NoteGroup.colors[index]} end');
			updateHitbox();

			offsetX += ((width / 2) - (width / 2)) + 17;

			if (downscroll)
				offsetY += ((height / 2) - (height / 2)) + 30;

			if (prevNote != null && prevNote.isSustain) {
				prevNote.playAnim('${NoteGroup.colors[index]} hold');
				prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * ((noteStepCrochet / 100) * 1.5 * speed);
				prevNote.updateHitbox();
			}
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

class Splash extends FNFSprite {
	public function new(type:String = "default"):Void {
		super(0, 0);
		this.loadFrames('images/notes/${type}/NOTE_splashes');
		for (n in 0...2)
			for (i in 0...NoteGroup.colors.length)
				this.addAnim('impact ${NoteGroup.colors[i]}${n}', '${NoteGroup.colors[i]} splash ${n}', null, 24);
		this.moves = false;
	}

	public override function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
		super.playAnim(name, force, reversed, frame);

		centerOrigin();
		centerOffsets();
	}
}
