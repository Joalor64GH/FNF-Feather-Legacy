package game.options;

class OptionsPage {
	public var pageName:String = "default";
	public var pageOptions:Array<String> = [];

	public function new(pageName:String, ?pageOptions:Array<String>):Void {
		this.pageName = pageName;
		this.pageOptions = pageOptions;
	}
}
