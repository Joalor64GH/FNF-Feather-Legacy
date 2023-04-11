package feather.core.data;

#if DISCORD_ENABLED
import discord_rpc.DiscordRpc;
#end
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.Assets as OpenFLAssets;
import sys.FileSystem;
import sys.io.File;
#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

enum PurgeDefinition {
	STORED_IMAGES;
	UNUSED_IMAGES;
	CACHED_SOUNDS;
}

enum EngineOrigin {
	/**
	 * Characters: JSON
	 * Charts: heavily modified base
	 */
	PSYCH_ENGINE;

	/**
	 * Characters: Scripts (hscript)
	 * Charts: Same as base
	 */
	FOREVER_ENGINE;

	/**
	 * Characters: JSON
	 * Charts: unique format
	 */
	CROW_ENGINE;
}

enum abstract AssetType(String) to String from String {
	var FONT:AssetType = 'font';
	var IMAGE:AssetType = 'image';
	var SOUND:AssetType = 'sound';
	// TEXT TYPES
	var XML:AssetType = 'xml';
	var JSON:AssetType = 'json';
	var YAML:AssetType = 'yaml';
	var SCRIPT:AssetType = 'script';
	var TXT:AssetType = 'txt';
	var JSON_ATLAS:AssetType = 'json_atlas';

	public function cycleExtensions(path:String):String {
		if (getExtension() != null) {
			for (i in getExtension())
				if (sys.FileSystem.exists('${path}${i}'))
					return '${path}${i}';
		}

		return '${path}';
	}

	public function getExtension():Array<String> {
		return switch (this) {
			case IMAGE: ['.png', '.jpg', '.bmp'];
			case SOUND: ['.mp3', '.ogg', '.wav'];
			case SCRIPT: ['.hx', '.hxs', '.hxc', '.hscript', '.hxclass'];
			case FONT: ['.ttf', '.otf'];
			case TXT: ['.txt'];
			case XML: ['.xml'];
			case JSON: ['.json'];
			case YAML: ['.yaml', '.yml'];
			default: null;
		}
	}

	public function toOpenFL():openfl.utils.AssetType {
		return switch (this) {
			case IMAGE: openfl.utils.AssetType.IMAGE;
			case SOUND: openfl.utils.AssetType.SOUND;
			case TXT | XML | JSON | SCRIPT: openfl.utils.AssetType.TEXT;
			case FONT: openfl.utils.AssetType.FONT;
			default: openfl.utils.AssetType.BINARY;
		}
	}
}

class AssetHandler {
	public static function getPath(?folder:String, ?type:AssetType, ?disregardMods:Bool = false):String {
		var pathBase:String = 'assets';
		if (folder != null) {
			if (folder.startsWith("assets"))
				pathBase = '';
			folder = '/${folder}';
		}

		var returnPath:String = type.cycleExtensions('${pathBase}${folder}');

		// prioritize mod assets
		#if MODDING_ENABLED
		if (!disregardMods)
			if (FileSystem.exists(ModHandler.getPath(folder, type)))
				returnPath = ModHandler.getPath(folder, type);
		#end

		return returnPath;
	}

	public static function getAsset(folder:String, ?type:AssetType, ?disregardMods:Bool = false):Dynamic {
		var finalPath:String = getPath(folder, type, disregardMods);

		return switch (type) {
			case IMAGE: CacheHandler.getGraphicData(finalPath);
			case SOUND: CacheHandler.getSoundData(finalPath);
			case XML: FlxAtlasFrames.fromSparrow(getAsset(folder, IMAGE), File.getContent(getPath(folder, XML)));
			case TXT: FlxAtlasFrames.fromSpriteSheetPacker(getAsset(folder, IMAGE), getPath(folder, TXT));
			case JSON | YAML:
				var file = sys.io.File.getContent(finalPath);

				if (type == JSON)
					while (!file.endsWith("}"))
						file = file.substr(0, file.length - 1);

				file;
			case JSON_ATLAS:
				return flxanimate.frames.FlxAnimateFrames.fromJson(getAsset(folder, JSON), getAsset(folder, IMAGE));
			default: finalPath;
		}
	}

	public static function preload(file:String, type:AssetType = IMAGE):Void {
		return switch (type) {
			case IMAGE: CacheHandler.getGraphicData(file);
			case SOUND: CacheHandler.getSoundData(file);
			default:
		}
	}

	public static function getExtensionsFor(type:AssetType):Array<String>
		return type.getExtension();
}

class CacheHandler {
	public static var cachedGraphics:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var cachedSounds:Map<String, Sound> = new Map<String, Sound>();

	public static var trackedIDs:Array<String> = [];

	public static function getGraphicData(path:String):FlxGraphic {
		if (!cachedGraphics.exists(path)) {
			var newGraphic:FlxGraphic = null;

			try newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path), false, path) catch (e:haxe.Exception) {
				newGraphic = FlxGraphic.fromRectangle(100, 100, 0xFFAAAAAA);
				trace('image graphic at "${path}" could not be loaded.');
			}

			newGraphic.persist = true;
			cachedGraphics.set(path, newGraphic);
			trackedIDs.push(path);
			return newGraphic;
		} else if (cachedGraphics.get(path) != null)
			return cachedGraphics.get(path);

		trace('image asset at "${path}" is returning null, called from "${Type.getClass(FlxG.state)}"');
		return null;
	}

	public static function getSoundData(path:String):Sound {
		if (!cachedSounds.exists(path)) {
			var newSound:Sound = Sound.fromFile(path);
			cachedSounds.set(path, newSound);
			trackedIDs.push(path);
			return cachedSounds.get(path);
		} else {
			if (cachedSounds.get(path) != null)
				return cachedSounds.get(path);
		}

		trace('sound asset at "${path}" is returning null, called from "${Type.getClass(FlxG.state)}"');
		return null;
	}

	public static function purge(?definitions:Array<PurgeDefinition>):Void {
		// definitions are optional
		if (definitions == null)
			definitions = [UNUSED_IMAGES, CACHED_SOUNDS];

		var funcsToExec:Array<Void->Void> = [];

		if (definitions.contains(STORED_IMAGES))
			funcsToExec.push(_purgeStored);
		if (definitions.contains(CACHED_SOUNDS))
			funcsToExec.push(_purgeSounds);
		if (definitions.contains(UNUSED_IMAGES))
			funcsToExec.push(_purgeUnused);

		if (funcsToExec.length > 0)
			for (i in 0...funcsToExec.length)
				funcsToExec[i]();
	}

	static function _purgeStored():Void {
		@:privateAccess {
			for (data in FlxG.bitmap._cache.keys()) {
				if (!trackedIDs.contains(data)) {
					var dataGraphic:FlxGraphic = FlxG.bitmap._cache.get(data);
					OpenFLAssets.cache.removeBitmapData(data);
					OpenFLAssets.cache.clear(data);
					FlxG.bitmap._cache.remove(data);
					dataGraphic.destroy();
				}
			}
		}
		trackedIDs = [];
	}

	static function _purgeUnused():Void {
		for (data in cachedGraphics.keys()) {
			@:privateAccess
			{
				if (!trackedIDs.contains(data)) {
					var dataGraphic:FlxGraphic = cachedGraphics.get(data);
					OpenFLAssets.cache.removeBitmapData(data);
					OpenFLAssets.cache.clear(data);
					FlxG.bitmap._cache.remove(data);
					cachedGraphics.remove(data);
					dataGraphic.destroy();
				}
			}
		}
		gcRun(true);
	}

	static function _purgeSounds():Void {
		for (data in cachedSounds.keys()) {
			if (!trackedIDs.contains(data)) {
				OpenFLAssets.cache.clear(data);
				cachedSounds.remove(data);
			}
		}
	}

	public static function gcEnable():Void {
		#if (cpp || hl) Gc.enable(true); #end
	}

	public static function gcDisable():Void {
		#if (cpp || hl) Gc.enable(false); #end
	}

	public static function gcRun(major:Bool = false):Void {
		#if (cpp || java || neko)
		Gc.run(major);
		#elseif hl
		Gc.major();
		#else
		openfl.system.System.gc();
		#end

		#if cpp
		Gc.compact();
		#end
	}
}

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

class ScriptHandler extends SScript {
	public var presets:Array<Dynamic> = [];
	public var folder:String = null;

	public function new(file:String, ?_folder:String = null, ?myPresets:Array<Dynamic>):Void {
		super(file);

		folder = _folder;

		// default imports
		presets.push(flixel.FlxG);
		presets.push(flixel.FlxSprite);
		presets.push(flixel.math.FlxMath);
		presets.push(flixel.tweens.FlxEase);
		presets.push(flixel.tweens.FlxTween);
		presets.push(flixel.util.FlxTimer);
		presets.push(StringTools);
		presets.push(feather.core.Utils);

		if (myPresets != null && myPresets.length > 0)
			for (i in 0...myPresets.length)
				presets.push(myPresets[i]);

		if (folder != null)
			set('Paths', new ScriptPaths(folder));

		// @:privateAccess trace(parsingExceptions);
	}

	public override function preset():Void {
		super.preset();

		for (i in 0...presets.length)
			setClass(presets[i]);
	}
}

/**
 * Copy of the Paths class, extended for scripts
 */
class ScriptPaths {
	public var location:String = null;

	public function new(_location:String):Void {
		location = _location;
		trace('created new local path on ${_location}');
	}

	public inline function getPath(path:String, ?type:AssetType):String {
		// trace('path requested by ${location} was ${path}');
		return type.cycleExtensions('${location}/${path}');
	}

	public inline function font(font:String):String
		return getPath('fonts/${font}', FONT);

	public inline function image(image:String):FlxGraphic
		return CacheHandler.getGraphicData(getPath('images/${image}', IMAGE));

	public inline function sound(sound:String):Sound
		return CacheHandler.getSoundData(getPath('sounds/${sound}', SOUND));

	public inline function getSparrowAtlas(xml:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(image('${xml}'), File.getContent(getPath('images/${xml}', XML)));

	public inline function getPackerAtlas(txt:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSpriteSheetPacker(image('${txt}'), getPath('images/${txt}', TXT));
}
