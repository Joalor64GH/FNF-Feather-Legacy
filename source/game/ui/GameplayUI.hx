package game.ui;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;
import game.PlayState;
import game.system.Conductor;

class GameplayUI extends FlxSpriteGroup {
	final game:PlayState = PlayState.self;

	public var healthBG:FlxSprite;
	public var healthBar:FlxBar;

	public var iconPL:HealthIcon;
	public var iconOPP:HealthIcon;

	public var scoreText:FlxText;
	public var infoText:FlxText;
	public var cpuText:FlxText;

	public var downscroll:Bool = Settings.get("scrollType") == "DOWN";

	public function new():Void {
		super();

		var barY:Float = FlxG.height * 0.90;
		if (downscroll)
			barY = FlxG.height * 0.11;

		healthBG = new FlxSprite(0, barY).loadGraphic(Utils.getUIAsset('healthBar'));
		healthBG.screenCenter(X);
		add(healthBG);

		healthBar = new FlxBar(healthBG.x + 4, healthBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBG.width - 8), Std.int(healthBG.height - 8));
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		add(healthBar);

		iconPL = new HealthIcon(game.player.icon, true);
		iconPL.y = healthBar.y - (iconPL.height / 2);
		iconPL.scrollFactor.set();
		add(iconPL);

		iconOPP = new HealthIcon(game.opponent.icon, false);
		iconOPP.y = healthBar.y - (iconOPP.height / 2);
		iconOPP.scrollFactor.set();
		add(iconOPP);

		scoreText = new FlxText(0, healthBG.y + 45, Std.int(healthBG.width + 55));
		scoreText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 18, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		add(scoreText);

		if (Settings.get("infoText") != 'NONE') {
			infoText = new FlxText(0, 0, 0, Settings.get("infoText") == 'SONG' ? '- ${game.song.name} -' : '');
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

		var engineName:String = 'Feather';
		if (Main.featherVer.branch != '' && Main.featherVer.branch != null)
			engineName += ' ${Main.featherVer.branch}';

		var featherText:FlxText = new FlxText(0, 0, 0, '[${engineName.toUpperCase()} v${Main.featherVer.number}]');
		featherText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 18, 0xFFFFFFFF, RIGHT, OUTLINE, 0xFF000000);
		featherText.setPosition(FlxG.width - featherText.width - 5, FlxG.height - featherText.height - 5);
		add(featherText);

		forEachOfType(FlxText, function(text:FlxText):Void text.borderSize = 1.5);
		antialiasing = Settings.get("antialiasing");
		updateScore(true);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		healthBar.percent = game.currentStat.health * 50;

		var iconOffset:Int = 26;
		iconPL.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconOPP.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconOPP.width - iconOffset);

		iconPL.updateAnim(healthBar.percent);
		iconOPP.updateAnim(100 - healthBar.percent);

		if (Settings.get("infoText") == 'TIME') {
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

	var scoreTween:FlxTween;

	public function updateScore(miss:Bool = false):Void {
		var newScore:String = '[ SCORE: ${game.currentStat.score}';
		newScore += separator + 'MISSES: ${game.currentStat.misses}${game.currentStat.clearType}';
		newScore += separator + 'GRADE: ${game.currentStat.gradeType} [${game.currentStat.getPercent()}%] ]';
		scoreText.text = newScore;

		scoreText.screenCenter(X);

		if (!miss) {
			scoreText.scale.set(1.05, 1.05);

			if (scoreTween != null)
				scoreTween.cancel();

			scoreTween = FlxTween.tween(scoreText, {"scale.x": 1, "scale.y": 1}, 0.6,
				{ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween):Void scoreTween = null});
		}
	}

	public function beatHit(curBeat:Int):Void {
		iconPL.beatHit(curBeat);
		iconOPP.beatHit(curBeat);
	}
}
