package feather.stage;

/**
 * Week 1: Tutorial, Bopeebo, Fresh, Dadbattle
 */
class Stage extends BaseStage {
	public function new():Void {
		super();

		var stageBack:FlxSprite = new FlxSprite(-600, -200).loadGraphic(getObject('stage/stageback'));
		add(stageBack);

		var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(getObject('stage/stagecurtains'));
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.scrollFactor.set(1.3, 1.3);
		add(stageCurtains);

		var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(getObject('stage/stagefront'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.scrollFactor.set(0.9, 0.9);
		add(stageFront);

		// set antialiasing
		forEachOfType(FlxSprite, function(sprite:FlxSprite):Void sprite.antialiasing = UserSettings.get("antialiasing"));
	}
}
