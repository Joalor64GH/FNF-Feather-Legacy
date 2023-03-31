package game.menus;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import game.MusicBeatState.MusicBeatSubState;
import game.system.Option;
import game.system.OptionList;

class OptionsMenu extends MusicBeatSubState {
	public var curSelection:Int = 0;

	public var pageBG:FlxSprite;
	public var pageGroup:FlxTypedGroup<FlxText>;
	public var descriptionHolder:FlxText;

	public var pageOptions:Array<Option> = [];

	public var onPause:Bool = false;

	public function new(onPause:Bool = false):Void {
		super();
		this.onPause = onPause;

		pageOptions = OptionList.get();
	}

	public override function create():Void {
		super.create();

		if (!onPause) {
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/menuBGBlue'));
			bg.screenCenter(XY);
			bg.scrollFactor.set();
			bg.alpha = 0.8;
			add(bg);
		}

		pageBG = new FlxSprite().makeGraphic(Std.int(FlxG.width / 1.3), Std.int(FlxG.height / 1.1), FlxColor.BLACK);
		pageBG.screenCenter(XY);
		pageBG.alpha = 0;
		add(pageBG);

		pageGroup = new FlxTypedGroup<FlxText>();

		for (i in 0...pageOptions.length) {
			var name:FlxText = new FlxText(pageBG.x + 10, (40 * i) + pageBG.y + 10, pageBG.width, '${pageOptions[i].name}: ${getValueText(i)}');
			name.setFormat(Paths.font('vcr'), 32, (onPause && pageOptions[i].lockOnPause) ? 0xFFFFFF00 : 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
			name.alpha = 0;
			name.ID = i;
			pageGroup.add(name);

			FlxTween.tween(name, {alpha: 0.6}, 0.4);
		}
		add(pageGroup);

		descriptionHolder = new FlxText(pageBG.x + 10, pageBG.height, pageBG.width, '');
		descriptionHolder.setFormat(Paths.font('vcr'), 20, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		add(descriptionHolder);

		FlxTween.tween(pageBG, {alpha: 0.6}, 0.6, {
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

				if (controls.justPressed("back")) {
					if (onPause)
						close();
					else
						FlxG.switchState(new game.menus.MainMenu());
				}

				if (controls.justPressed("accept")) {
					if (onPause && pageOptions[curSelection].lockOnPause)
						return;

					FlxG.sound.play(Paths.sound('scrollMenu'));
					isChanging = !isChanging;
				}
			} else {
				if (controls.anyJustPressed(["left", "right"])) {
					var option:Option = pageOptions[curSelection];
					switch (option.type) {
						case Checkmark:
							option.value = !option.value;

						case StringList:
							var storedValue:Int = 0;
							for (i in 0...option.optionsList.length) {
								if (option.optionsList[i] == getValueText(curSelection))
									storedValue = i;

								option.maximum = option.optionsList.length - 1;
							}

							var nextValue:Int = controls.justPressed("left") ? -1 : 1;
							var wrapValue:Int = FlxMath.wrap(storedValue + nextValue, option.minimum, option.maximum);
							option.value = option.optionsList[wrapValue];

						case Number:
							var nextValue:Int = controls.justPressed("left") ? -1 : 1;
							var keyValue:Int = Settings.get(option.apiKey) + option.decimals * nextValue;
							if (keyValue < option.minimum || keyValue > option.maximum)
								keyValue = Settings.get(option.apiKey) + nextValue;

							option.value = FlxMath.wrap(keyValue, option.minimum, option.maximum);
					}

					pageGroup.members[curSelection].text = '${option.name}: ${getValueText(curSelection)}';
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (controls.justPressed("back")) {
					Settings.save();
					Settings.update();
					FlxG.sound.play(Paths.sound('cancelMenu'));
					isChanging = false;
				}
			}
		}
	}

	public function getValueText(index:Int):String {
		return switch (pageOptions[index].value) {
			case "true": "ON";
			case "false": "OFF";
			default: pageOptions[index].value;
		}
	}

	public function updateSelection(newSelection:Int = 0):Void {
		if (pageGroup.members != null && pageGroup.members.length > 0)
			curSelection = FlxMath.wrap(curSelection + newSelection, 0, Std.int(pageGroup.members.length - 1));

		if (newSelection != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		var pauseLock:Bool = (onPause && pageOptions[curSelection].lockOnPause);
		descriptionHolder.text = pauseLock ? 'This option cannot be changed while on the Pause Menu.' : pageOptions[curSelection].description;
		descriptionHolder.color = pageGroup.members[curSelection].color;

		var ascendingIndex:Int = 0;
		for (option in pageGroup) {
			option.ID = ascendingIndex - curSelection;
			option.alpha = option.ID == 0 ? 1 : 0.6;
			++ascendingIndex;
		}
	}
}
