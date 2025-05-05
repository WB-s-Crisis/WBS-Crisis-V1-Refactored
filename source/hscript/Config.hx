package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
		#if !DOCUMENTATION
		"flixel",
		"openfl.display.Sprite",

		"funkin",
		#end
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		#if !DOCUMENTATION
		"flixel",
		"openfl",
		//需要调用
		"lime.ui",

		"haxe.xml",
		"haxe.CallStack",
		"funkin",
		#end
	];

	// Runs support for using in specific classes. 
	public static final ALLOWED_USING = [
		"StringTools",
		"funkin.backend.utils.CoolUtil",
	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [

	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		"funkin.backend.scripting.events.PlayAnimEvent", // Error: expected member name or ';' after declaration specifiers, Due to Func
	];

	public static final DISALLOW_USING = [

	];
}