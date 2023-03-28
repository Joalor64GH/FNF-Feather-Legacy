package game.stage;

/**
 * Week 2: Spookeez, South, Monster
 */
class HauntedHouse extends BaseStage
{
	public var halloweenBG:FlxSprite;

	public function new():Void
	{
		super();

		halloweenBG = new FlxSprite(-200, -100);
		halloweenBG.frames = getObject('spooky/halloween_bg', XML);
		halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
		halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
		halloweenBG.animation.play('idle');
		halloweenBG.antialiasing = true;
		add(halloweenBG);
	}

	var strikeBeat:Int = 0;
	var strikeOffset:Int = 8;

	public override function onBeat(curBeat:Int):Void
	{
		if (FlxG.random.bool(10) && curBeat > strikeBeat + strikeOffset)
		{
			halloweenBG.animation.play('lightning');
			game.player.playAnim('scared', true);
			game.crowd.playAnim('scared', true);

			FlxG.sound.play(getObject("spooky/sounds/thunder_" + FlxG.random.int(1, 2), SOUND));

			strikeBeat = curBeat;
			strikeOffset = FlxG.random.int(8, 24);
		}
	}
}
