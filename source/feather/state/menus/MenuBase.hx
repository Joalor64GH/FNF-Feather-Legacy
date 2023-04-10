package feather.state.menus;

import feather.gameObjs.ui.Alphabet;
import flixel.math.FlxMath;

typedef MenuOption = {
	var name:String;
	var callback:Void->Void;
};

/**
 * a Base Menu State for use with other menus
 */
class MenuBase extends MusicBeatState {
	public var curSelection:Int = 0;

	public var optionsGroup:AlphabetGroup;

	var holdTimer:Float = 0;
	var chagingConst:Bool = false;

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (controls.anyJustPressed(["up", "down"])) {
			updateSelection(controls.justPressed("up") ? -1 : 1);
			holdTimer = 0;
		}

		var timerCalc:Int = Std.int((holdTimer / 1) * 5);

		if (controls.anyPressed(["up", "down"])) {
			holdTimer += elapsed;

			var timerCalcPost:Int = Std.int((holdTimer / 1) * 5);

			if (holdTimer > 0.5)
				updateSelection((timerCalc - timerCalcPost) * (controls.pressed("down") ? -1 : 1));
			chagingConst = true;
		} else
			chagingConst = false;
	}

	public function updateSelection(newSelection:Int = 0):Void {
		if (optionsGroup.members != null && optionsGroup.members.length > 0)
			curSelection = FlxMath.wrap(curSelection + newSelection, 0, Std.int(optionsGroup.members.length - 1));

		if (newSelection != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		var ascendingIndex:Int = 0;
		for (option in optionsGroup) {
			option.groupIndex = ascendingIndex - curSelection;
			option.alpha = option.groupIndex == 0 ? 1 : 0.6;
			++ascendingIndex;
		}
	}
}
