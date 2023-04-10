package feather.core.handlers;

import discord_rpc.DiscordRpc;

class DiscordHandler {
	public static var eventInitialized:Bool = false;

	public static function init(initID:String):Void {
		DiscordRpc.start({
			clientID: initID,
			onReady: eventRDY,
			onDisconnected: eventERR,
			onError: eventERR
		});
		lime.app.Application.current.onExit.add((e:Dynamic) -> DiscordRpc.shutdown());

		if (!eventInitialized)
			eventRDY();
	}

	public static function updateInfo(state:String, details:String, ?imgBig:String = 'icon', ?imgSmall:String, ?imgDetails:String, ?smallImgDetails:String,
			?showTimestamps:Bool = false, ?timeEnd:Float):Void {
		if (!eventInitialized)
			return;

		if (imgDetails == null)
			imgDetails = 'Version: ${Main.featherVer}';

		var timeNow:Float = (showTimestamps ? Date.now().getTime() : 0);
		if (timeEnd > 0)
			timeEnd = timeNow + timeEnd;

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: imgBig,
			smallImageKey: imgSmall,
			largeImageText: imgDetails,
			smallImageText: smallImgDetails,
			startTimestamp: Std.int(timeNow / 1000),
			endTimestamp: Std.int(timeEnd / 1000)
		});
	}

	@:noPrivateAccess
	static function eventRDY():Void {
		trace('[DISCORD]: Wrapper initialized');
		updateInfo('In Menus', 'IDLING');
		eventInitialized = true;
	}

	@:noPrivateAccess
	static function eventDC(code:Int, msg:String):Void {
		trace('[DISCORD]: Disconnected! ${code} : ${msg}');
	}

	@:noPrivateAccess
	static function eventERR(code:Int, msg:String):Void {
		trace('[DISCORD]: Error! ${code} : ${msg}');
	}
}
