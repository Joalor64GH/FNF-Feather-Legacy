package feather.gameObjs;

import feather.core.FNFSprite;
import feather.core.music.Conductor;
import feather.gameObjs.Note.Splash;
import feather.state.PlayState;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;

class Notefield extends FlxGroup {
	final game:PlayState = PlayState.self;

	public static final colors:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static final directions:Array<String> = ['left', 'down', 'up', 'right'];

	/**
	 * How many notes do this instance have?
	 */
	public var keys:Int = 4;

	/**
	 * How much spaced out should this instance be?
	 */
	public var spacing:Float = 160 * 0.7;

	/**
	 * Whether this instance automatically hits notes by itself
	 */
	public var cpuControlled:Bool = false;

	public var receptorObjects:FlxTypedGroup<FNFSprite>;
	public var splashObjects:FlxTypedGroup<FNFSprite>;
	public var noteObjects:FlxTypedGroup<Note>;

	public var character:Character;

	public function new(x:Float = 0, y:Float = 0, ?character:Character, ?spacing:Float = 160 * 0.7, ?keys:Int = 4):Void {
		super();

		this.keys = keys;
		this.character = character;
		this.spacing = spacing;

		receptorObjects = new FlxTypedGroup<FNFSprite>();
		splashObjects = new FlxTypedGroup<FNFSprite>();
		noteObjects = new FlxTypedGroup<Note>();

		generateArrows(x, y);

		add(receptorObjects);
		add(noteObjects);
		add(splashObjects);
	}

	/**
	 * Note Regeneration Script
	 */
	public function generateArrows(x:Float = 0, y:Float = 0):Void {
		receptorObjects.forEachAlive(function(receptor:FlxSprite):Void {
			receptor.kill();
			receptor.destroy();
		});

		splashObjects.forEachAlive(function(splash:FNFSprite):Void {
			splash.kill();
			splash.destroy();
		});

		for (i in 0...keys) {
			var receptor:FNFSprite = new FNFSprite(x, y).loadFrames('images/notes/default/NOTE_strum');

			receptor.addAnim('static', 'arrow${directions[i].toUpperCase()}');
			receptor.addAnim('pressed', '${directions[i].toLowerCase()} press');
			receptor.addAnim('confirm', '${directions[i].toLowerCase()} confirm');

			receptor.x += spacing * i;
			receptor.ID = i;

			receptor.setGraphicSize(Std.int(receptor.width * 0.7));
			receptor.updateHitbox();

			receptor.antialiasing = UserSettings.get("antialiasing");

			receptor.animation.finishCallback = function(name:String):Void {
				if (name == 'confirm') {
					receptor.playAnim(cpuControlled ? 'static' : 'pressed', true);
					receptor.centerOrigin();
					receptor.centerOffsets();
				}
			};

			receptor.playAnim('static');
			receptor.centerOrigin();
			receptor.centerOffsets();

			receptorObjects.add(receptor);
		}
	}

	public function doSplash(index:Int, type:String, preload:Bool = false):Void {
		if (!UserSettings.get("noteSplashes")
			|| (UserSettings.get("noteSplashes") && !sys.FileSystem.exists(Paths.getPath('images/notes/${type}/NOTE_splashes', XML))))
			return;

		var receptor:FNFSprite = receptorObjects.members[index];

		var splash:FNFSprite = splashObjects.recycle(FNFSprite, function():FNFSprite return new Splash(index, type));
		splash.alpha = preload ? 0.000001 : 1;
		splash.scale.set(1, 1);

		splash.antialiasing = UserSettings.get("antialiasing");
		splash.depth = -Conductor.songPosition;

		splash.alpha = 0.6;
		splash.setPosition(receptor.x - receptor.width, receptor.y - receptor.height);
		splash.playAnim('impact ${colors[index]}0' /*+ FlxG.random.int(0, 1)*/);
		if (preload)
			splashObjects.add(splash);

		splash.animation.finishCallback = function(name:String):Void {
			if (splash.animation != null && splash.animation.curAnim.finished)
				splash.kill();
		}

		splashObjects.sort(FNFSprite.depthOrder, flixel.util.FlxSort.DESCENDING);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (receptorObjects == null || noteObjects == null || noteObjects.members.length < 1)
			return;

		noteObjects.forEachAlive(function(note:Note):Void {
			var receptor:FlxSprite = receptorObjects.members[note.index];

			if (note != null && receptor != null) {
				var center:Float = receptor.y + spacing / 2;
				var stepY:Float = (Conductor.songPosition - note.stepTime) * (0.45 * FlxMath.roundDecimal(note.noteSpeed, 2));

				note.x = receptor.x;
				if (note.downscroll)
					note.y = receptor.y + stepY;
				else // I'm gonna throw up.
					note.y = receptor.y - stepY;

				note.x += note.offX;
				note.y += note.offY;

				if (note.isSustain) {
					if (note.downscroll) {
						if (note.animation.curAnim != null && note.animation.curAnim.name.endsWith("end")) {
							if (note.prevNote != null && note.prevNote.isSustain)
								note.y += Math.ceil(/*note.prevNote.y - */ note.prevNote.frameHeight);
						}

						if (note.y - note.offset.y * note.scale.y + note.height >= center
							&& (note.mustHit || (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit)))) {
							var swagRect = new FlxRect(0, 0, note.frameWidth, note.frameHeight);
							swagRect.height = (center - note.y) / note.scale.y;
							swagRect.y = note.frameHeight - swagRect.height;
							note.clipRect = swagRect;
						}
					} else {
						if (note.y + note.offset.y * note.scale.y <= center
							&& (note.mustHit || (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit)))) {
							var swagRect = new FlxRect(0, 0, note.width / note.scale.x, note.height / note.scale.y);
							swagRect.y = (center - note.y) / note.scale.y;
							swagRect.height -= swagRect.y;
							note.clipRect = swagRect;
						}
					}
				}
			}
		});
	}

	public override function add(Object:FlxBasic):FlxBasic {
		if (Object is Note) {
			var noteObject:Note = cast(Object, Note);
			if (noteObject != null)
				noteObjects.add(noteObject);
		}
		return super.add(Object);
	}

	public override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic {
		if (Object is Note) {
			var note:Note = cast(Object, Note);
			if (note != null) {
				note.kill();
				note.destroy();
			}
			noteObjects.remove(note, Splice);
		}

		return super.remove(Object, Splice);
	}

	public function currentAnim(anim:String, index:Int):Bool {
		if (receptorObjects.members[index] != null) {
			var receptor:FlxSprite = receptorObjects.members[index];
			if (receptor.animation.curAnim != null && receptor.animation.curAnim.name == anim)
				return true;
		}
		return false;
	}

	public function playAnim(anim:String, index:Int, forced:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		if (receptorObjects.members[index] == null)
			return;

		var receptor:FNFSprite = receptorObjects.members[index];
		if (receptor.animation.getByName(anim) != null)
			receptor.playAnim(anim, forced, reversed, frame);

		receptor.centerOrigin();
		receptor.centerOffsets();
	}
}
