package game.subStates;

import core.assets.ModHandler;
import flixel.FlxG;
import flixel.group.FlxGroup;
import game.MusicBeatState.MusicBeatSubState;
import game.ui.Alphabet;

class ModMenuSubState extends MusicBeatSubState {
	static var curSelection:Int = 0;

	public var repositionMode:Bool = false;

	public var modGroup:FlxTypedGroup<Alphabet>;

	public function new():Void {
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0.6;
		add(bg);

		modGroup = new FlxTypedGroup<Alphabet>();

		for (i in 0...ModHandler.trackedMods.length) {
			var modEntry:Alphabet = new Alphabet(0, (60 * i), ModHandler.trackedMods[i].name);
			modEntry.menuItem = true;
			modEntry.groupIndex = i;
			modGroup.add(modEntry);
		}

		add(modGroup);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (controls.justPressed("back"))
			close();
	}
}
