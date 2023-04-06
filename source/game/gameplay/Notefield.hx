package game.gameplay;

import core.FNFSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import game.gameplay.Note.Splash;
import game.system.Conductor;

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

	public var receptors:FlxTypedGroup<FNFSprite> = new FlxTypedGroup<FNFSprite>();
	public var noteSprites:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var splashSprites:FlxTypedGroup<FNFSprite> = new FlxTypedGroup<FNFSprite>();

	public var character:Character;

	public function new(x:Float = 0, y:Float = 0, ?character:Character, ?spacing:Float = 160 * 0.7, ?keys:Int = 4):Void {
		super();

		this.keys = keys;
		this.character = character;
		this.spacing = spacing;

		generateArrows(x, y);

		add(receptors);
		add(noteSprites);
		add(splashSprites);
	}

	/**
	 * Note Regeneration Script
	 */
	public function generateArrows(x:Float = 0, y:Float = 0):Void {
		receptors.forEachAlive(function(receptor:FlxSprite):Void {
			receptor.kill();
			receptor.destroy();
		});

		splashSprites.forEachAlive(function(splash:FNFSprite):Void {
			splash.kill();
			splash.destroy();
		});

		for (i in 0...keys) {
			var receptor:FNFSprite = new FNFSprite(x, y).loadFrames('images/notes/default/NOTE_assets');

			receptor.addAnim('static', 'arrow static ${i}');
			receptor.addAnim('pressed', '${directions[i]} press');
			receptor.addAnim('confirm', '${directions[i]} confirm');

			receptor.x += spacing * i;
			receptor.ID = i;

			receptor.setGraphicSize(Std.int(receptor.width * 0.7));
			receptor.updateHitbox();

			receptor.antialiasing = Settings.get("antialiasing");

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

			receptors.add(receptor);
		}

		doSplash(0, "default", true);
	}

	public function doSplash(index:Int, type:String = "default", preload:Bool = false):Void {
		if (!Settings.get("noteSplashes"))
			return;

		var receptor:FNFSprite = receptors.members[index];

		var splash:FNFSprite = splashSprites.recycle(FNFSprite, function():FNFSprite return new Splash(type));
		splash.alpha = preload ? 0.000001 : 1;
		splash.scale.set(1, 1);

		splash.antialiasing = Settings.get("antialiasing");
		splash.depth = -Conductor.songPosition;
		splash.setPosition(receptor.x - receptor.width, receptor.y - receptor.height);
		splash.playAnim('impact ${colors[index]}0' /*+ FlxG.random.int(0, 1)*/);
		if (preload)
			splashSprites.add(splash);

		splash.animation.finishCallback = function(name:String):Void {
			if (splash.animation != null && splash.animation.curAnim.finished)
				splash.kill();
		}

		splashSprites.sort((Order:Int, a:FNFSprite, b:FNFSprite) -> return a.depth > b.depth ? -Order : Order, flixel.util.FlxSort.DESCENDING);
	}

	public override function update(elapsed:Float):Void {
		if (receptors != null) {
			noteSprites.forEachAlive(function(note:Note):Void {
				var receptor:FlxSprite = receptors.members[note.index];

				if (note != null && receptor != null) {
					var mustHit:Bool = note.strumline != game.playerStrumline;
					var center:Float = receptor.y + spacing / 2;
					var stepY:Float = (Conductor.songPosition - note.step) * (0.45 * FlxMath.roundDecimal(note.speed, 2));

					note.x = receptor.x;
					if (note.downscroll)
						note.arrow.y = receptor.y + stepY;
					else // I'm gonna throw up.
						note.arrow.y = receptor.y - stepY;

					if (note.isSustain) {
						if (note.downscroll) {
							if (note.animation.curAnim != null && note.animation.curAnim.name.endsWith("end")) {
								if (note.prevNote != null && note.prevNote.isSustain)
									note.y += Math.ceil(/*note.prevNote.y -*/ note.prevNote.frameHeight);
							}

							if (note.y - note.offset.y * note.scale.y + note.height >= center
								&& (mustHit || (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit)))) {
								var swagRect = new FlxRect(0, 0, note.frameWidth, note.frameHeight);
								swagRect.height = (center - note.y) / note.scale.y;
								swagRect.y = note.frameHeight - swagRect.height;
								note.clipRect = swagRect;
							}
						} else {
							if (note.y + note.offset.y * note.scale.y <= center
								&& (mustHit || (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit)))) {
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

		super.update(elapsed);
	}

	public override function add(Object:FlxBasic):FlxBasic {
		if (Object is Note) {
			var noteObject:Note = cast(Object, Note);
			if (noteObject != null)
				noteSprites.add(noteObject);
		}
		return super.add(Object);
	}

	public override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic {
		if (Object is Note) {
			var note:Note = cast(Object, Note);

			note.kill();
			note.destroy();

			noteSprites.remove(note, Splice);
		}

		return super.remove(Object, Splice);
	}

	public function currentAnim(anim:String, index:Int):Bool {
		if (receptors.members[index] != null) {
			var receptor:FlxSprite = receptors.members[index];
			if (receptor.animation.curAnim != null && receptor.animation.curAnim.name == anim)
				return true;
		}
		return false;
	}

	public function playAnim(anim:String, index:Int, forced:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		if (receptors.members[index] == null)
			return;

		var receptor:FNFSprite = receptors.members[index];
		if (receptor.animation.getByName(anim) != null)
			receptor.playAnim(anim, forced, reversed, frame);

		receptor.centerOrigin();
		receptor.centerOffsets();
	}
}
