package game.ui;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;
import game.PlayState;
import rhythm.Conductor;

class GameplayUI extends FlxSpriteGroup
{
	final game:PlayState = PlayState.self;

	public var healthBG:FlxSprite;
	public var healthBar:FlxBar;

	public var scoreText:FlxText;
	public var timeText:FlxText;

	public function new():Void
	{
		super();

		var barY:Float = FlxG.height * 0.90;
		if (game.downscroll)
			barY = FlxG.height * 0.11;

		healthBG = new FlxSprite(0, barY).loadGraphic(FtrAssets.getUIAsset('healthBar'));
		healthBG.screenCenter(X);
		add(healthBG);

		healthBar = new FlxBar(healthBG.x + 4, healthBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBG.width - 8), Std.int(healthBG.height - 8));
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		add(healthBar);

		scoreText = new FlxText(0, healthBG.y + 25, Std.int(healthBG.width + 55), '');
		scoreText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 18, 0xFFFFFFFF, CENTER, OUTLINE_FAST, 0xFF000000);
		add(scoreText);

		timeText = new FlxText(0, 0, 0, '');
		timeText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 23, 0xFFFFFFFF, CENTER, OUTLINE_FAST, 0xFF000000);
		add(timeText);

		var featherText:FlxText = new FlxText(0, 0, '[FEATHER BETA v${lime.app.Application.current.meta.get("version")}]');
		featherText.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 18, 0xFFFFFFFF, RIGHT, OUTLINE_FAST, 0xFF000000);
		featherText.setPosition(FlxG.width - featherText.width - 5, FlxG.height - featherText.height - 5);
		add(featherText);

		forEachOfType(FlxText, function(text:FlxText):Void text.borderSize = 1.5);

		updateScore();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		healthBar.percent = game.currentStat.health * 50;

		if (game != null && timeText != null && Conductor.songPosition > 0)
		{
			var time:Float = Math.floor(Conductor.songPosition / 1000);
			var length:Float = Math.floor(game.music.inst.length / 1000);

			timeText.text = '- ${FlxStringUtil.formatTime(time)} / ${FlxStringUtil.formatTime(length)} -';
			timeText.y = game.downscroll ? FlxG.height - timeText.height - 15 : 15;
			timeText.screenCenter(X);
		}
	}

	public var separator:String = ' ~ ';

	public function updateScore():Void
	{
		var newScore:String = '[SCORE]: ${game.currentStat.score}';
		newScore += separator + '[MISSES]: ${game.currentStat.misses}${game.currentStat.clearType}';
		newScore += separator + '[GRADE]: ${game.currentStat.gradeType} [${game.currentStat.getPercent()}%]';
		scoreText.text = newScore;

		scoreText.screenCenter(X);
	}
}
