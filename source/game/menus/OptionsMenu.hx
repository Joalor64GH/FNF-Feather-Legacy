package game.menus;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import game.MusicBeatState.MusicBeatSubState;
import game.system.options.Option;
import game.system.options.OptionCategory;
import game.system.options.OptionList;

class OptionsMenu extends MusicBeatSubState {
	public var curSelection:Int = 0;
	public var curHorizontal:Int = 0;

	public var blackBG:FlxSprite;
	public var descriptionHolder:FlxText;

	public var selectedText:FlxText;
	public var curCategory:OptionCategory;
	public var curOption:Option;

	public var options:Array<OptionCategory> = [];
	public var onPause:Bool = false;

	public function new(onPause:Bool = false):Void {
		super();
		this.onPause = onPause;
	}

	public override function create():Void {
		super.create();

		blackBG = new FlxSprite().makeGraphic(Std.int(FlxG.width / 1.3), Std.int(FlxG.height / 1.1), FlxColor.BLACK);
		blackBG.screenCenter(XY);
		blackBG.alpha = 0;
		add(blackBG);

		options.push(new OptionCategory(blackBG.x, blackBG.y + 10, "Main", OptionList.get()));
		for (i in 0...options.length)
			add(options[i].optionObjects);

		descriptionHolder = new FlxText(blackBG.x + 10, blackBG.height, blackBG.width, '');
		descriptionHolder.setFormat(Paths.font('vcr'), 20, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		add(descriptionHolder);

		FlxTween.tween(blackBG, {alpha: 0.6}, 0.6, {
			onComplete: function(twn:FlxTween):Void {
				lockedMovement = false;
				updateSelection();
			}
		});
	}

	var holdTimer:Float = 0;
	var lockedMovement:Bool = true;
	var isChanging:Bool = false;

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!lockedMovement) {
			if (!isChanging) {
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
				}

				if (controls.anyJustPressed(["left", "right"]))
					updateCategory(controls.justPressed("left") ? -1 : 1);

				if (controls.justPressed("back"))
					close();

				if (controls.justPressed("accept")) {
					if (onPause && curOption.lockOnPause)
						return;

					FlxG.sound.play(Paths.sound('scrollMenu'));
					isChanging = !isChanging;
				}
			} else {
				if (controls.anyJustPressed(["left", "right"])) {
					updateCategory();

					switch (curOption.type) {
						case Checkmark:
							curOption.value = !curOption.value;

						case StringList:
							var storedValue:Int = 0;
							for (i in 0...curOption.optionsList.length) {
								if (curOption.optionsList[i] == getValueText(curSelection))
									storedValue = i;

								curOption.maximum = curOption.optionsList.length - 1;
							}

							var nextValue:Int = controls.justPressed("left") ? -1 : 1;
							var wrapValue:Int = FlxMath.wrap(storedValue + nextValue, curOption.minimum, curOption.maximum);
							curOption.value = curOption.optionsList[wrapValue];

						case Number:
							var nextValue:Int = controls.justPressed("left") ? -1 : 1;
							var keyValue:Int = UserSettings.get(curOption.apiKey) + curOption.decimals * nextValue;
							if (keyValue < curOption.minimum || keyValue > curOption.maximum)
								keyValue = UserSettings.get(curOption.apiKey) + nextValue;

							curOption.value = FlxMath.wrap(keyValue, curOption.minimum, curOption.maximum);
					}

					selectedText.text = '${curOption.name}: ${getValueText(curSelection)}';
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (controls.justPressed("back")) {
					UserSettings.save();
					UserSettings.update();
					FlxG.sound.play(Paths.sound('cancelMenu'));
					isChanging = false;
				}
			}
		}
	}

	public function getValueText(index:Int):String {
		return switch (curCategory.options[index].value) {
			case "true": "ON";
			case "false": "OFF";
			default: curCategory.options[index].value;
		}
	}

	public function updateSelection(newSelection:Int = 0):Void {
		updateCategory();

		curSelection = FlxMath.wrap(curSelection + newSelection, 0, Std.int(curCategory.options.length - 1));
		if (newSelection != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		if (onPause && curOption.lockOnPause) {
			selectedText.color = 0xFFFFFF00;
			descriptionHolder.text = 'This option cannot be changed while on the Pause Menu.';
		} else
			descriptionHolder.text = curOption.description;

		descriptionHolder.color = selectedText.color;

		var ascendingIndex:Int = 0;
		for (option in curCategory.optionObjects) {
			option.ID = ascendingIndex - curSelection;
			option.alpha = option.ID == 0 ? 1 : 0.6;
			++ascendingIndex;
		}
	}

	public function updateCategory(newCategory:Int = 0):Void {
		if (options != null && options[curHorizontal] != null) {
			curCategory = options[curHorizontal];
			curOption = options[curHorizontal].options[curSelection];
			selectedText = options[curHorizontal].optionObjects.members[curSelection];
		}

		curHorizontal = FlxMath.wrap(curHorizontal + newCategory, 0, options.length - 1);
	}
}
