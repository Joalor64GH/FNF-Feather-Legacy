package feather.gameObjs.ui;

import feather.core.music.Conductor;
import feather.state.PlayState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;

class GameplayUI extends FlxSpriteGroup {
	final game:PlayState = PlayState.self;

	public var healthBG:FlxSprite;
	public var healthBar:FlxBar;

	public var iconPL:HealthIcon;
	public var iconOPP:HealthIcon;

	public var scoreText:FlxText;
	public var infoText:FlxText;
	public var cpuText:FlxText;

	var healthLerp:Float = 1;
	var downscroll:Bool = UserSettings.get("scrollType") == "DOWN";

	public function new():Void {
		super();

		var barY:Float = FlxG.height * 0.90;
		if (downscroll)
			barY = FlxG.height * 0.11;

		healthBG = new FlxSprite(0, barY).loadGraphic(Utils.getUIAsset('healthBar'));
		healthBG.screenCenter(X);
		add(healthBG);

		healthBar = new FlxBar(healthBG.x + 4, healthBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBG.width - 8), Std.int(healthBG.height - 8), this, 'healthLerp');
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		add(healthBar);

		iconPL = new HealthIcon(game.player.icon, true);
		iconPL.y = healthBar.y - (iconPL.height / 2);
		add(iconPL);

		iconOPP = new HealthIcon(game.enemy.icon, false);
		iconOPP.y = healthBar.y - (iconOPP.height / 2);
		add(iconOPP);

		scoreText = new FlxText(healthBG.x + 50, healthBG.y + 50, Std.int(healthBG.width + 50));
		scoreText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 20, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		add(scoreText);

		if (UserSettings.get("infoText") != 'NONE') {
			infoText = new FlxText(0, 0, 0, UserSettings.get("infoText") == 'SONG' ? '- ${game.songMetadata.name} -' : '');
			infoText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 20, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
			infoText.y = downscroll ? FlxG.height - infoText.height - 15 : 15;
			infoText.screenCenter(X);
			add(infoText);
		}

		cpuText = new FlxText(0, 0, 0, '[CPU]');
		cpuText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 32, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		cpuText.y = downscroll ? FlxG.height - cpuText.height - 85 : 85;
		cpuText.visible = false;
		cpuText.screenCenter(X);
		cpuText.alpha = 0.6;
		add(cpuText);

		forEachOfType(FlxText, function(text:FlxText):Void text.borderSize = 1.5);
		forEach(function(object:FlxSprite):Void object.antialiasing = UserSettings.get("antialiasing"));
		updateScore(true);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		healthBar.percent = game.currentStat.health * 50;
		healthLerp = FlxMath.lerp(healthLerp, game.currentStat.health, FlxMath.bound(elapsed * 20, 0, 1));

		var iconOffset:Int = 26;
		var percent:Float = 1 - (healthLerp / 2);
		iconPL.x = healthBar.x + (healthBar.width * percent) + (150 * iconPL.scale.x - 150) / 2 - iconOffset;
		iconOPP.x = healthBar.x + (healthBar.width * percent) - (150 * iconOPP.scale.x) / 2 - iconOffset * 2;

		iconPL.updateAnim(healthBar.percent);
		iconOPP.updateAnim(100 - healthBar.percent);

		if (UserSettings.get("infoText") == 'TIME') {
			if (game != null && infoText != null && Conductor.songPosition > 0) {
				var time:Float = Math.floor(Conductor.songPosition / 1000);
				var length:Float = Math.floor(game.music.inst.length / 1000);

				infoText.text = '- ${FlxStringUtil.formatTime(time)} / ${FlxStringUtil.formatTime(length)} -';
				infoText.y = downscroll ? FlxG.height - infoText.height - 15 : 15;
				infoText.screenCenter(X);
			}
		}
	}

	public var separator:String = ' ~ ';

	public function updateScore(miss:Bool = false):Void {
		var score:Int = game.currentStat.score;
		var misses:Int = game.currentStat.misses;
		var clear:String = game.currentStat.clearType;
		var percent:Float = game.currentStat.getPercent();
		var grade:String = game.currentStat.gradeType;

		var myScore:String = misses == 1 ? 'MISS: ' : 'MISSES: ' + '${misses}${clear}';
		myScore += separator + 'SCORE: ${score}';
		myScore += separator + '${percent}% [${grade}]';
		scoreText.text = myScore;

		scoreText.screenCenter(X);
	}

	public function onBeat(curBeat:Int):Void {
		iconPL.onBeat(curBeat);
		iconOPP.onBeat(curBeat);
	}
}
