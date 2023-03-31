package game.menus;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import game.MusicBeatState.MusicBeatSubState;
import game.options.Option;

class OptionsMenu extends MusicBeatSubState {
	public var curSelection:Int = 0;

	public var pageGroup:FlxTypedGroup<FlxText>;
	public var descriptionHolder:FlxText;

	public var pageOptions:Array<Option> = [
		new Option("Scroll Type", "In which direction should notes spawn?", "scrollType", ["UP", "DOWN"]),
		new Option("Ghost Tapping", "If mashing keys should be allowed during gameplay.", "ghostTapping"),
		new Option("Info Display", "Choose what to display on the info text (usually shows time)", "infoText", ["TIME", "SONG", "NONE"]),
	];

	public var onPause:Bool = false;

	public function new(onPause:Bool = false):Void {
		super();
		this.onPause = onPause;
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

		var pageBG:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width / 1.3), Std.int(FlxG.height / 1.1), FlxColor.BLACK);
		pageBG.screenCenter(XY);
		pageBG.alpha = 0;
		add(pageBG);

		pageGroup = new FlxTypedGroup<FlxText>();

		for (i in 0...pageOptions.length) {
			var value:String = switch (pageOptions[i].getValue()) {
				case "true": "ON";
				case "false": "OFF";
				default: pageOptions[i].getValue();
			}

			var name:FlxText = new FlxText(pageBG.x + 10, (40 * i) + pageBG.y + 10, pageBG.width, '${pageOptions[i].name}: ${value}');
			name.setFormat(Paths.font('vcr'), 32, 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
			name.alpha = 0;
			name.ID = i;
			pageGroup.add(name);

			FlxTween.tween(name, {alpha: 0.6}, 0.4);
		}

		add(pageGroup);

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
					FlxG.sound.play(Paths.sound('scrollMenu'));
					isChanging = !isChanging;
				}
			} else {
				if (controls.anyJustPressed(["left", "right"])) {
					switch (pageOptions[curSelection].type) {
						case Checkmark:
							// if (!pageOptions[curSelection].mustReset)
							pageOptions[curSelection].setValue(!Settings.get(pageOptions[curSelection].apiKey));

						case StringList:
							var storedValue:Int = 0;
							for (i in 0...pageOptions[curSelection].optionsList.length) {
								if (pageOptions[curSelection].optionsList[i] == getValueText())
									storedValue = i;

								pageOptions[curSelection].maximum = pageOptions[curSelection].optionsList.length - 1;
							}

							var wrapValue:Int = 0;
							var nextValue:Int = controls.justPressed("left") ? -1 : 1;

							wrapValue = FlxMath.wrap(storedValue + nextValue, pageOptions[curSelection].minimum, pageOptions[curSelection].maximum);
							pageOptions[curSelection].setValue(pageOptions[curSelection].optionsList[wrapValue]);
					}

					pageGroup.members[curSelection].text = '${pageOptions[curSelection].name}: ${getValueText()}';
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (controls.justPressed("back")) {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					isChanging = false;
				}
			}
		}
	}

	public function getValueText():String {
		return switch (pageOptions[curSelection].getValue()) {
			case "true": "ON";
			case "false": "OFF";
			default: pageOptions[curSelection].getValue();
		}
	}

	public function updateSelection(newSelection:Int = 0):Void {
		if (pageGroup.members != null && pageGroup.members.length > 0)
			curSelection = FlxMath.wrap(curSelection + newSelection, 0, Std.int(pageGroup.members.length - 1));

		if (newSelection != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		var ascendingIndex:Int = 0;
		for (option in pageGroup) {
			option.ID = ascendingIndex - curSelection;
			option.alpha = option.ID == 0 ? 1 : 0.6;
			++ascendingIndex;
		}
	}
}
