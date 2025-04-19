package funkin.extra;

import flixel.FlxState;
import hxvlc.openfl.Video;
import hxvlc.flixel.FlxVideoSprite;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;

/**
 * 废物东西
 * 请说，哦多桑
 * 爸爸...诶，儿子乖
 */
class UnusedVideoState extends FlxState {
	public static var canSkip(default, set):Bool = false;
	@:noCompletion private static function set_canSkip(val:Bool):Bool {
		if(save != null) {
			Reflect.setField(save.data, "canSkip", val);
			save.flush();
		}

		canSkip = val;
		return val;
	}
	
	public static var save:FlxSave = null;
	public static function init() {
		if(save == null) {
			save = new FlxSave();
			save.bind("unusedVideo");
			if(Reflect.hasField(save.data, "canSkip")) {
				canSkip = save.data.canSkip;
			}
		}
	}

	public var skipText:FlxText;

	public var video:FlxVideoSprite;
	var started:Bool = false;
	var finished:Bool = false;
	var preFinished:Bool = false;
	
	private var realCanSkip:Bool = false;
	private var autoVolumeHandle:Bool = false;
	
	var startDelay:Float = 0.001;

	var path:String;
	var callbackOptions:CallbackOptions;
	
	var nextState:FlxState;

	public function new(path:String, nextState:FlxState, ?startDelay:Float = 0.001, ?autoVolumeHandle:Bool = false, ?callbackOptions:CallbackOptions) {
		super();
		
		this.path = path;
		this.nextState = nextState;
		this.autoVolumeHandle = autoVolumeHandle;
		if(callbackOptions != null)
			this.callbackOptions = callbackOptions;
		
		if(startDelay >= 0.001)
			this.startDelay = startDelay;
	}
	
	public override function create() {
		video = new FlxVideoSprite(0, 0);
		video.antialiasing = true;
		video.autoVolumeHandle = this.autoVolumeHandle;
		video.bitmap.onFormatSetup.add(function() {
			if(video.bitmap != null && video.bitmap.bitmapData != null) {
				video.setGraphicSize(FlxG.width, FlxG.height);
				video.updateHitbox();
			}
		});
		video.bitmap.onEndReached.add(finish);
		video.bitmap.onPlaying.add(() -> {
			started = true;
			if(Reflect.hasField(this.callbackOptions, "onStart") && this.callbackOptions.onStart != null) {
				this.callbackOptions.onStart(this);
			}
			
			if(canSkip) {
				FlxTween.tween(skipText, {alpha: 1}, 0.25, {startDelay: 1.5, onComplete: function(tween:FlxTween) {
					realCanSkip = true;
				}});
			}else canSkip = true;
		});
	
		if(video.load(this.path))
			new FlxTimer().start(this.startDelay, function(tmr:FlxTimer) {
				video.play();
			});
	
		add(video);
		
		skipText = new FlxText(0, 0, FlxG.width, "臭人机", 24);
		skipText.setFormat(Paths.font("vcr.ttf"), #if mobile 24 #else 18 #end, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF6A0000);
		//skipText.screenCenter(FlxAxes.X);
		skipText.y = 615;
		skipText.borderSize = 2;
		skipText.alpha = 0;
		skipText.text = #if TOUCH_CONTROLS 'Touch Screen To Skip' #else 'Press Enter To Skip' #end;
		add(skipText);
	
		super.create();
	}
	
	public override function update(elapsed:Float) {
		super.update(elapsed);
		
		if(started && (!finished || !preFinished)) {
			if(Reflect.hasField(this.callbackOptions, "onUpdate") && this.callbackOptions.onUpdate != null) {
				this.callbackOptions.onUpdate(this, elapsed);
			}
			
			if(realCanSkip) {
				#if TOUCH_CONTROLS
				for(touch in FlxG.touches.list) {
					if(touch.justPressed) {
						preFinished = true;
						finish();
						realCanSkip = false;
						break;
					}
				}
				#else
				if(FlxG.keys.justPressed.ENTER) {
					preFinished = true;
					finish();
					realCanSkip = false;
				}
				#end
			}
		}
	}
	
	private function finish():Void {
		if(!video.active) return;
		if(!preFinished)
		        finished = true;
		
		if(preFinished) {
			if(Reflect.hasField(this.callbackOptions, "onFinish") && this.callbackOptions.onFinish != null) {
			        this.callbackOptions.onFinish(this);
		        }
			
			for(sb in [skipText, video]) {
				FlxTween.tween(sb, {alpha: 0}, 0.75, {onComplete: function(tween:FlxTween) {
					new FlxTimer().start(1.2, function(tmr:FlxTimer) {
						FlxG.switchState(nextState);
					});
					video.destroy();
				}});
			}
			FlxTween.num(100, 0, 0.75, function(val:Float) {
				video.bitmap.volume = Math.floor(val);
			});
		}else {
			if(Reflect.hasField(this.callbackOptions, "onFinish") && this.callbackOptions.onFinish != null) {
			        this.callbackOptions.onFinish(this);
		        }
			
			new FlxTimer().start(1.2, function(tmr:FlxTimer) {
				FlxG.switchState(nextState);
			});
			video.destroy();
		}
	}
}

typedef CallbackOptions = {
	var ?onFinish:UnusedVideoState->Void;
	var ?onStart:UnusedVideoState->Void;
	var ?onUpdate:UnusedVideoState->Float->Void;
}
