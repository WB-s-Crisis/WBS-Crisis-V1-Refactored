package funkin.backend.system.framerate;

import funkin.backend.system.debugText.DebugPrint.OUTLINE;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import funkin.backend.utils.MemoryUtil;
import openfl.filters.ShaderFilter;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;

import lime.system.System as LimeSystem;

class Framerate extends Sprite {
	public static var instance:Framerate = null;
	public static var fontName:String = Paths.font("Super Cartoon.ttf");
	public static final os:String = 'OS Build: ${LimeSystem.platformName}[${LimeSystem.deviceVendor}(${LimeSystem.deviceModel})]-${LimeSystem.platformVersion}.';

	public var offset:FlxPoint;

	public var fpsText:TextField = null;
	public var osText:TextField = null;
	public var memoryText:TextField = null;
	public var memoryPeakText:TextField = null;

	public var currentFPS:Int;
	private var cacheCount:Int;
	private var currentTime:Float;
	private var times:Array<Float>;

	private var memoryPeak:Float = 0;

	public function new(?outline:Bool = true) {
		super();

		initVars();

		final jiange:Float = 2;

		fpsText = new TextField();
		fpsText.defaultTextFormat = new TextFormat(fontName, #if mobile 16 #else 12 #end, FlxColor.WHITE);
		fpsText.autoSize = TextFieldAutoSize.LEFT;

		fpsText.text = "FPS: 0";
		addChild(fpsText);

		memoryText = new TextField();
		memoryText.defaultTextFormat = new TextFormat(fontName, #if mobile 16 #else 12 #end, FlxColor.WHITE);
		memoryText.autoSize = TextFieldAutoSize.LEFT;
		memoryText.y = fpsText.height + jiange;

		memoryPeakText = new TextField();
		memoryPeakText.defaultTextFormat = new TextFormat(fontName, #if mobile 16 #else 12 #end, FlxColor.WHITE);
		memoryPeakText.autoSize = TextFieldAutoSize.LEFT;
		memoryPeakText.y = memoryText.y + fpsText.height + jiange;

		memoryText.text = "Memory: 0.00MB/0.00MB";
		memoryPeakText.text = "Memory Peak: 0.00MB";
		addChild(memoryText);
		addChild(memoryPeakText);

		osText = new TextField();
		osText.defaultTextFormat = new TextFormat(fontName, #if mobile 16 #else 12 #end, FlxColor.WHITE);
		osText.autoSize = TextFieldAutoSize.LEFT;
		osText.y = memoryPeakText.y + fpsText.height + jiange;

		final dddd:String = os.replace("null", "{* No Revice}");
		osText.text = dddd;
		addChild(osText);

		if(outline) {
			this.filters = [new ShaderFilter(new OUTLINE({
				size: #if mobile 0.07 #else 0.02 #end,
				color: 0xFF6A0000
			}))];
		}

		instance = this;
	}

	private static var visibleOneshot:Bool = false;

	override function __enterFrame(deltaTime:Float) {
		this.x = #if mobile 0.294117 * FlxG.game.x + #end offset.x;
		this.y = offset.y;

		if(!Options.fpsCounter) {
			this.visible = false;

			if(!visibleOneshot) {
				visibleOneshot = true;
				times.clear();
			}

			return;
		}else {
			if(visibleOneshot) {
				visibleOneshot = false;
				visible = true;
			}
		}
		
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);

		if (currentCount != cacheCount && fpsText.visible)
			fpsText.text = "FPS: " + FlxMath.bound(currentFPS, 0, FlxG.drawFramerate);

		cacheCount = currentCount;

		final qqqebIsALazyBoy:Float = MemoryUtil.currentMemUsage();
		if(qqqebIsALazyBoy > memoryPeak) memoryPeak = qqqebIsALazyBoy;
		memoryText.text = 'Memory: ${FlxStringUtil.formatBytes(qqqebIsALazyBoy)}/${FlxStringUtil.formatBytes(MemoryUtil.getTotalMem() * 1024*1024)}';
		memoryPeakText.text = 'Memory Peak: ${FlxStringUtil.formatBytes(memoryPeak)}';
	}

	public inline function setScale(?scale:Float){
		if(scale == null)
			scale = Math.min(FlxG.stage.window.width / FlxG.width, FlxG.stage.window.height / FlxG.height);
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
	}

	private function initVars():Void {
		offset = FlxPoint.get();
		
		currentFPS = 0;
		cacheCount = 0;
		currentTime = 0.;
		times = [];
	}
}
