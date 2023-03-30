package game.gameplay;

import core.FNFSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import game.gameplay.Note.Splash;
import game.system.music.Conductor;

class NoteGroup extends FlxGroup
{
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

	public var babyArrows:FlxTypedGroup<FNFSprite> = new FlxTypedGroup<FNFSprite>();
	public var noteSprites:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var splashSprites:FlxTypedGroup<FNFSprite> = new FlxTypedGroup<FNFSprite>();

	public var character:Character;

	public function new(x:Float = 0, y:Float = 0, ?cpuControlled:Bool = true, ?character:Character, ?keys:Int = 4):Void
	{
		super();

		this.keys = keys;
		this.cpuControlled = cpuControlled;
		this.character = character;

		generateArrows(x, y);

		add(babyArrows);
		add(noteSprites);
		add(splashSprites);
	}

	/**
	 * Note Regeneration Script
	 */
	public function generateArrows(x:Float = 0, y:Float = 0):Void
	{
		babyArrows.forEachAlive(function(babyArrow:FlxSprite):Void
		{
			babyArrow.kill();
			babyArrow.destroy();
		});

		splashSprites.forEachAlive(function(splash:FNFSprite):Void
		{
			splash.kill();
			splash.destroy();
		});

		for (i in 0...keys)
		{
			var babyArrow:FNFSprite = new FNFSprite(x, y).loadFrames('images/notes/default/NOTE_assets');

			babyArrow.addAnim('static', 'arrow static ${i}');
			babyArrow.addAnim('pressed', '${directions[i]} press');
			babyArrow.addAnim('confirm', '${directions[i]} confirm');

			babyArrow.x += spacing * i;
			babyArrow.ID = i;

			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
			babyArrow.updateHitbox();

			babyArrow.animation.finishCallback = function(name:String):Void
			{
				if (name == 'confirm')
				{
					babyArrow.playAnim(cpuControlled ? 'static' : 'pressed', true);
					babyArrow.centerOrigin();
					babyArrow.centerOffsets();
				}
			};

			babyArrow.playAnim('static');
			babyArrow.centerOrigin();
			babyArrow.centerOffsets();

			babyArrows.add(babyArrow);
		}

		doSplash(0, "default", true);
	}

	public function doSplash(index:Int, type:String = "default", preload:Bool = false):Void
	{
		var babyArrow:FNFSprite = babyArrows.members[index];

		var splash:FNFSprite = splashSprites.recycle(FNFSprite, function():FNFSprite return new Splash(type));
		splash.alpha = preload ? 0.000001 : 1;
		splash.scale.set(1, 1);

		splash.depth = -Conductor.songPosition;
		splash.setPosition(babyArrow.x - babyArrow.width, babyArrow.y - babyArrow.height);
		splash.playAnim('impact ${colors[index]}0' /*+ FlxG.random.int(0, 1)*/);
		if (preload)
			splashSprites.add(splash);

		splash.animation.finishCallback = function(name:String):Void
		{
			if (splash.animation != null && splash.animation.curAnim.finished)
				splash.kill();
		}

		splashSprites.sort((Order:Int, a:FNFSprite, b:FNFSprite) -> return a.depth > b.depth ? -Order : Order);
	}

	public override function update(elapsed:Float):Void
	{
		if (babyArrows != null)
		{
			noteSprites.forEachAlive(function(note:Note):Void
			{
				var babyArrow:FlxSprite = babyArrows.members[note.index];

				if (note != null && babyArrow != null)
				{
					var mustHit:Bool = note.strumline != game.playerStrumline;
					var center:Float = babyArrow.y + spacing / 2;
					var stepY:Float = (Conductor.songPosition - note.step) * (0.45 * FlxMath.roundDecimal(note.speed, 2));

					note.x = babyArrow.x;
					if (note.downscroll)
						note.y = babyArrow.y + stepY;
					else // I'm gonna throw up.
						note.y = babyArrow.y - stepY;

					note.x += note.offsetX;
					note.y += note.offsetY;

					if (note.isSustain)
					{
						if (note.downscroll)
						{
							if (note.isEnd && note.prevNote != null)
							{
								if (note.prevNote.isSustain)
									note.y += Math.ceil(/*note.prevNote.y -*/ note.prevNote.frameHeight);
							}

							if (note.y - note.offset.y * note.scale.y + note.height >= center
								&& (mustHit || (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit))))
							{
								var swagRect = new FlxRect(0, 0, note.frameWidth, note.frameHeight);
								swagRect.height = (center - note.y) / note.scale.y;
								swagRect.y = note.frameHeight - swagRect.height;
								note.clipRect = swagRect;
							}
						}
						else
						{
							if (note.y + note.offset.y * note.scale.y <= center
								&& (mustHit || (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit))))
							{
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

	public override function add(Object:FlxBasic):FlxBasic
	{
		if (Object is Note)
			noteSprites.add(cast(Object, Note));
		return super.add(Object);
	}

	public override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic
	{
		if (Object is Note)
		{
			var note:Note = cast(Object, Note);

			note.kill();
			note.destroy();

			noteSprites.remove(note, Splice);
		}

		return super.remove(Object, Splice);
	}

	public function currentAnim(anim:String, index:Int):Bool
	{
		if (babyArrows.members[index] != null)
		{
			var babyArrow:FlxSprite = babyArrows.members[index];
			if (babyArrow.animation.curAnim != null && babyArrow.animation.curAnim.name == anim)
				return true;
		}
		return false;
	}

	public function playAnim(anim:String, index:Int, forced:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		if (babyArrows.members[index] == null)
			return;

		var babyArrow:FNFSprite = babyArrows.members[index];
		if (babyArrow.animation.getByName(anim) != null)
			babyArrow.playAnim(anim, forced, reversed, frame);

		babyArrow.centerOrigin();
		babyArrow.centerOffsets();
	}
}
