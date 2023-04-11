package feather.state.menus;

import feather.state.menus.MenuBase.MenuOption;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

class MainMenu extends MusicBeatState {
	static var curSelection:Int = 0;

	public var optionsGroup:FlxTypedGroup<MainMenuItem>;

	public var optionsList:Array<MenuOption> = [
		{name: 'story mode', callback: /*function():Void MusicBeatState.switchState(new StoryMenu())*/ null},
		{name: 'freeplay', callback: function():Void MusicBeatState.switchState(new FreeplayMenu())},
		{name: 'credits', callback: function():Void MusicBeatState.switchState(new CreditsMenu())},
		{name: 'options', callback: function():Void FlxG.state.openSubState(new OptionsMenu())}
	];

	var bg:FlxSprite;
	var magenta:FlxSprite;

	public override function create():Void {
		super.create();

		#if MODDING_ENABLED
		feather.core.data.ModHandler.scanMods();
		#end
		#if DISCORD_ENABLED
		DiscordHandler.updateInfo('In the Menus', 'MAIN MENU');
		#end

		feather.core.music.Levels.loadLevels();
		Utils.resetMusic();

		bg = new FlxSprite().loadGraphic(Paths.image('menus/menuBG'));
		bg.screenCenter();
		// bg.blend = DIFFERENCE;
		add(bg);

		magenta = new FlxSprite().loadGraphic(Paths.image('menus/menuBGMagenta'));
		magenta.screenCenter();
		magenta.visible = false;
		add(magenta);

		optionsGroup = new FlxTypedGroup<MainMenuItem>();
		add(optionsGroup);

		for (i in 0...optionsList.length) {
			var option:MainMenuItem = new MainMenuItem(0, 60 + (i * 160), optionsList[i].name);
			option.screenCenter(X);
			option.ID = i;

			option.deselectItem = function():Void {
				if (option.type != 'graphic')
					option.animation.play('idle', true);
				else
					option.scale.set(1, 1);
			}

			option.selectItem = function():Void {
				if (option.type != 'graphic') {
					option.animation.play('selected', true);
					// camFollow.setPosition(option.getGraphicMidpoint().x, option.getGraphicMidpoint().y + 80);
				} else
					option.scale.set(0.9, 0.9);
			}

			optionsGroup.add(option);
		}

		var versionText:FlxText = new FlxText(0, 0, 0, 'Funkin\' v${Main.fnfVer.toString()}\nFeather v${Main.featherVer.toString()}');
		versionText.setFormat(Paths.font('vcr'), 16, FlxColor.WHITE, LEFT, OUTLINE, 0xFF000000);
		versionText.setPosition(5, FlxG.height - versionText.height - 5);
		add(versionText);

		updateSelection();
	}

	var holdTimer:Float = 0;
	var lockedMovement:Bool = false;

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!lockedMovement) {
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

			if (controls.justPressed("accept")) {
				lockedMovement = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				if (magenta != null)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				optionsGroup.forEach(function(spr:MainMenuItem):Void {
					if (curSelection != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween):Void spr.kill()
						});
					} else {
						FlxFlicker.flicker(spr, 1, 0.10, optionsList[curSelection].name == 'options', false, function(flick:FlxFlicker):Void {
							if (optionsList[curSelection].callback != null)
								optionsList[curSelection].callback();
							else
								FlxG.resetState();
						});
					}
				});
			}

			#if MODDING_ENABLED
			if (FlxG.keys.justPressed.SHIFT) {
				persistentUpdate = false;
				openSubState(new feather.state.subState.ModMenuSubState());
			}
			#end

			if (FlxG.keys.justPressed.SEVEN)
				MusicBeatState.switchState(new test.NoteRenderTest());

			/*
				if (controls.justPressed("back"))
					MusicBeatState.switchState(new TitleScreen());
			 */
		}
	}

	function updateSelection(newSelection:Int = 0):Void {
		curSelection = FlxMath.wrap(curSelection + newSelection, 0, optionsGroup.length - 1);

		if (newSelection != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		optionsGroup.forEach(function(spr:MainMenuItem):Void {
			if (spr.deselectItem != null)
				spr.deselectItem();

			if (spr.ID == curSelection)
				if (spr.selectItem != null)
					spr.selectItem();
		});
	}

	public override function closeSubState():Void {
		optionsGroup.forEach(function(spr:MainMenuItem):Void {
			spr.revive();

			FlxTween.tween(spr, {alpha: 1}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween):Void {
					lockedMovement = false;
					updateSelection();
				}
			});
		});
		super.closeSubState();
	}
}

class MainMenuItem extends FlxSprite {
	public var name:String;
	public var type:String = 'frames-sparrow';

	public var deselectItem:Void->Void = null;
	public var selectItem:Void->Void = null;

	public function new(x:Float = 0, y:Float = 0, name:String):Void {
		super(x, y);

		this.name = name;
		type = defineType();

		if (type.startsWith("frames-")) {
			frames = switch (type) {
				case "frames-packer":
					Paths.getPackerAtlas('menus/options/${name}');
				default:
					Paths.getSparrowAtlas('menus/options/${name}');
			}

			animation.addByPrefix('idle', "basic", 24, true);
			animation.addByPrefix('selected', "white", 24, true);
			animation.play('idle');
		} else
			loadGraphic(Paths.image('menus/options/${name}'));
	}

	public function defineType():String {
		if (sys.FileSystem.exists(AssetHandler.getPath('images/menus/options/${name}', XML)))
			return "frames-sparrow";
		else if (sys.FileSystem.exists(AssetHandler.getPath('images/menus/options/${name}', TXT)))
			return "frames-packer";
		return "graphic";
	}
}
