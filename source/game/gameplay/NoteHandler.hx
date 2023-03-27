package game.gameplay;

import core.FNFSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import game.states.PlayState;
import rhythm.Conductor;

using StringTools;

typedef NoteGroup = FlxTypedGroup<Note>;

// class Note extends FlxSpriteGroup
class Note extends FNFSprite
{
	final game:PlayState = PlayState.self;

	public var prevNote:Note = null;

	public var index:Int = 0;

	public var type:String = 'default';

	// note type parameters
	public var ignorable:Bool = false;
	public var doSplash:Bool = true;

	public var step:Float = 0.0;
	public var sustainTime:Float = 0.0;
	public var speed(default, set):Float = 1.0;

	function set_speed(newSpeed:Float):Float
	{
		if (speed != newSpeed)
		{
			speed = newSpeed;
			updateSustain();
		}
		return speed;
	}

	public var strumline:Int = 0; // replaced "canBeHit", value for bf is 1
	public var wasGoodHit:Bool = false;
	public var canHit:Bool = false;

	public var isSustain:Bool = false;
	public var downscroll:Bool = true;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var hitboxEarly:Float = 1;
	public var hitboxLate:Float = 1;

	final originalStepCrochet:Float = Conductor.stepCrochet;

	public function new(step:Float, index:Int, ?isSustain:Bool, ?type:String, ?prevNote:Note):Void
	{
		super(0, -2000);

		if (prevNote == null)
			prevNote = this;

		this.step = step;
		this.index = index;
		this.isSustain = isSustain;
		this.type = type;
		this.prevNote = prevNote;

		frames = AssetHandler.getAsset('images/notes/${type}/note', XML);
		addAnim('${colorArray()[index]} note', '${colorArray()[index]}0');
		addAnim('${colorArray()[index]} end', '${colorArray()[index]} hold end');
		addAnim('${colorArray()[index]} hold', '${colorArray()[index]} hold piece');
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		// sustains
		if (prevNote != null && isSustain)
		{
			if (downscroll)
				flipY = true;
			alpha = 0.6;
			hitboxEarly = 0.5;

			playAnim('${colorArray()[index]} end');
			updateHitbox();

			if (prevNote.isSustain)
			{
				prevNote.playAnim('${colorArray()[index]} hold');
				prevNote.updateHitbox();
			}
		}
		else if (!isSustain)
		{
			hitboxEarly = 1;
			playAnim('${colorArray()[index]} note');
		}
	}

	public final function colorArray():Array<String>
	{
		return ['purple', 'blue', 'green', 'red'];
	}

	public function updateSustain():Void
	{
		if (isSustain)
		{
			if (prevNote != null && prevNote.exists)
			{
				if (prevNote.isSustain)
				{
					prevNote.playAnim('${colorArray()[index]} hold');
					prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * ((originalStepCrochet / 50) * 2 * speed);
					prevNote.updateHitbox();
				}
				else
					offsetX = ((width / 2) - (width / 2)) + 50;
			}
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (this.strumline == game.playerStrumline)
		{
			this.canHit = (this.step > Conductor.songPosition - (Conductor.safeZone * this.hitboxEarly)
				&& this.step < Conductor.songPosition + (Conductor.safeZone * this.hitboxLate));
		}
		else
			this.canHit = false;
	}
}

class BabyGroup extends FlxGroup
{
	final game:PlayState = PlayState.self;

	public var colors:Array<String> = ['purple', 'blue', 'green', 'red'];
	public var directions:Array<String> = ['left', 'down', 'up', 'right'];

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

	public var noteSprites:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var splashSprites:FlxTypedGroup<FNFSprite> = new FlxTypedGroup<FNFSprite>();
	public var babyArrows:FlxTypedGroup<FNFSprite> = new FlxTypedGroup<FNFSprite>();

	public var character:Character;

	public function new(x:Float = 0, y:Float = 0, ?cpuControlled:Bool = true, ?character:Character, ?keys:Int = 4):Void
	{
		super();

		this.keys = keys;
		this.cpuControlled = cpuControlled;
		this.character = character;

		generateArrows(x, y);

		add(babyArrows);
		add(splashSprites);
		add(noteSprites);
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
			var babyArrow:FNFSprite = new FNFSprite(x, y);
			babyArrow.frames = AssetHandler.getAsset('images/notes/default/note', XML);

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
	}

	public function doSplash(index:Int, preload:Bool = false):Void
	{
		var splash:FNFSprite = splashSprites.recycle(FNFSprite, function():FNFSprite
		{
			var noteSplash:FNFSprite = new FNFSprite();
			noteSplash.frames = FtrAssets.getUIAsset('noteSplashes', XML);
			noteSplash.addAnim('splash0', '${colors[index]} splash 0');
			noteSplash.addAnim('splash1', '${colors[index]} splash 1');
			return noteSplash;
		});

		splash.alpha = preload ? 0.000001 : 1;
		splash.scale.set(1, 1);
		splash.playAnim('splash' + FlxG.random.int(0, 1));
		if (preload)
			splashSprites.add(splash);

		splash.animation.finishCallback = function(name:String):Void
		{
			if (splash.animation != null && splash.animation.curAnim.finished)
				splash.kill();
		}
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
					var center:Float = (babyArrow.y) + spacing / 2;

					note.x = babyArrow.x;
					note.y = (babyArrow.y) + (Conductor.songPosition - note.step) * (0.45 * FlxMath.roundDecimal(note.speed, 2));

					note.x += note.offsetX;
					note.y += note.offsetY;

					if (note.isSustain)
					{
						if (note.downscroll)
						{
							if (note.animation.curAnim != null && note.animation.curAnim.name.endsWith('end') && note.prevNote != null)
							{
								if (note.prevNote.isSustain)
									note.y += Math.ceil(/*note.prevNote.y -*/ note.prevNote.frameHeight);
							}

							if (note.y - note.offset.y * note.scale.y + note.height >= center
								&& (note.strumline != game.playerStrumline
									|| (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit))))
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
								&& (note.strumline != game.playerStrumline
									|| (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canHit))))
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
