package game.subStates;

import core.assets.ModHandler;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import game.MusicBeatState.MusicBeatSubState;
import game.ui.Alphabet;

class ModMenuSubState extends MusicBeatSubState {
	static var curSelection:Int = 0;

	public var repositionMode:Bool = false;

	public var bgGradient:FlxSprite;
	public var modGroup:AlphabetGroup;

	public function new():Void {
		super();

		bgGradient = flixel.util.FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF000000, 0xFFFFFFFF]);
		bgGradient.alpha = 0.6;
		add(bgGradient);

		modGroup = new AlphabetGroup();
		for (i in 0...ModHandler.trackedMods.length) {
			var modEntry:Alphabet = new Alphabet(0, (60 * i), ModHandler.trackedMods[i].name);
			modEntry.menuItem = true;
			// modEntry.scrollStyle = STILL;
			modEntry.groupIndex = i;
			modGroup.add(modEntry);
		}
		add(modGroup);

		updateSelection();
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (controls.anyJustPressed(["up", "down"]))
			updateSelection(controls.justPressed("up") ? -1 : 1);

		if (controls.justPressed("back"))
			close();
	}

	public function updateSelection(newSelection:Int = 0):Void {
		if (modGroup.members.length > 0)
			curSelection = FlxMath.wrap(curSelection + newSelection, 0, modGroup.members.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		bgGradient.color = ModHandler.trackedMods[curSelection].color;

		var ascendingIndex:Int = 0;
		for (letter in modGroup) {
			letter.groupIndex = ascendingIndex - curSelection;
			letter.alpha = 0.6;
			if (letter.groupIndex == 0)
				letter.alpha = 1;
			++ascendingIndex;
		}
	}
}
