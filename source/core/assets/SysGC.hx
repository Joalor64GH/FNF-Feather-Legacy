package core.assets;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end
import openfl.system.System;

/**
 * Class to Manage `cpp.vm.Gc` calls
 */
class SysGC
{
	public static function enable():Void
	{
		#if (cpp || hl) Gc.enable(true); #end
	}

	public static function disable():Void
	{
		#if (cpp || hl) Gc.enable(false); #end
	}

	public static function run(major:Bool = false):Void
	{
		#if (cpp || java || neko)
		Gc.run(major);
		#elseif hl
		Gc.major();
		#else
		System.gc();
		#end

		#if cpp
		Gc.compact();
		#end
	}
}
