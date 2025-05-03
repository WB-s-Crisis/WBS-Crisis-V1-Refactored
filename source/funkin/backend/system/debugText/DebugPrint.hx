package funkin.backend.system.debugText;

import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.system.FlxAssets;
import openfl.filters.ShaderFilter;

/**
 * 这里不好看
 */
class DebugPrint extends Sprite {
	public var downscroll:Bool;

	public var textFormat:TextFormat;
	public var outline:OUTLINE;

	private var hangju:Float = 2;

	public function new(textFormat:TextFormat, ?downScroll = false) {
		super();

		outline = new OUTLINE({
			size: 0.075,
			color: 0xFFA50000
		});
		//this.filters = [new ShaderFilter(outline)];
		
		downscroll = downScroll;
		this.textFormat = textFormat;
	}

	public function debugPrint(text:String, ?textOptions:TextOptions) {
		var print:DebugText = new DebugText(__children.length, textOptions != null && Reflect.hasField(textOptions, "delayTime") ? textOptions.delayTime : null);
		print.autoSize = TextFieldAutoSize.LEFT;

		if(textOptions != null && Reflect.hasField(textOptions, "style")) {
			print.textColor = textOptions.style;
		}else {
			print.textColor = NORMAL;
		}
		
		print.text = text;
		print.defaultTextFormat = this.textFormat;
		addChild(print);
	}

	public override function addChild(child:DisplayObject):DisplayObject {
		if(child is DebugText) {
			var realChild = cast(child, DebugText);
			//this.filters = [new ShaderFilter(outline)];

			realChild.lastTime = Lib.getTimer();
			realChild.y = this.downscroll ? FlxG.stage.stageHeight - realChild.height : 0;
			if(realChild.ID > 0) {
				updateChildrenPos(realChild);
			}
		}

		return super.addChild(child);
	}

	public override function removeChild(child:DisplayObject):DisplayObject {
		//this.filters = [new ShaderFilter(outline)];

		return super.removeChild(child);
	}

	public inline function resizePosition(X:Float, Y:Float, ?scale:Float) {
		setScale(scale);
		this.x = FlxG.game.x + X;
		this.y = Y;
	}

	public inline function setScale(?scale:Float){
		if(scale == null)
			scale = Math.min(FlxG.stage.window.width / FlxG.width, FlxG.stage.window.height / FlxG.height);
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
	}

	private function updateChildrenPos(child:DebugText):Void {
		if(__children.length > 0) {
			for(_child in __children) {
				_child.y += (this.downscroll ? -1 : 1) * (child.height + hangju);
			}
		}
	}

	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void {
		var elapsed:Float = FlxG.elapsed;

		x = FlxG.game.x + 2;

		if(__children.length > 0) {
			for(child in __children) {
				if(child is DebugText) {
					var realChild = cast(child, DebugText);

					if(realChild.lastTime + realChild.delayTime * 1000 < Lib.getTimer()) {
						realChild.alpha -= elapsed / 0.35;

						if(realChild.lastTime + realChild.delayTime * 1000 + 350 < Lib.getTimer()) {
							removeChild(realChild);
						}
					}
				}
			}
		}
	}

	@:noCompletion
	override function toString():String {
		return "拜托，这没意思，滚";
	}
}

/**
 * 由于openfl的TextField没有OUTLINE只能这么搞了
 */
class OUTLINE extends FlxShader {
	@:glFragmentSource("
#pragma header

uniform vec3 color;
uniform int samples;
uniform float size;

void main()
{
	vec2 iResolution = openfl_TextureSize;
	vec2 fragCoord = openfl_TextureCoordv.xy * iResolution;

	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec3 targetCol = color; //The color of the outline
    
    vec4 finalCol = vec4(0);
    
    float rads = ((360.0 / float(samples)) * 3.14159265359) / 180.0;	//radians based on SAMPLES
    
    for(int i = 0; i < samples; i++)
    {
        if(finalCol.w < 0.1)
        {
        	float r = float(i + 1) * rads;
    		vec2 offset = vec2(cos(r) * 0.1, -sin(r)) * size; //calculate vector based on current radians and multiply by magnitude
    		finalCol = texture2D(bitmap, uv + offset);	//render the texture to the pixel on an offset UV
            if(finalCol.w > 0.0)
            {
                finalCol.xyz = targetCol;
            }
        }
    }
    
    vec4 tex = texture2D(bitmap, uv);
    if(tex.w > 0.0)
    {
     	finalCol = tex;   //if the centered texture's alpha is greater than 0, set finalcol to tex
    }
    
	gl_FragColor = finalCol;
}
	")
	public function new(?defaultValue:{
		var ?color:FlxColor;
		var ?size:Float;
		var ?fast:Bool;
	}) {
		super();

		color.value = [0.1, 0, 0];
		size.value = [0.05];
		samples.value = [8];
		
		if(defaultValue != null) {
			if(Reflect.hasField(defaultValue, "color")) {
				color.value = [defaultValue.color.redFloat, defaultValue.color.greenFloat, defaultValue.color.blueFloat];
			}

			if(Reflect.hasField(defaultValue, "size")) {
				size.value = [defaultValue.size];
			}

			if(Reflect.hasField(defaultValue, "fast")) {
				samples.value = [(defaultValue.fast ? 4 : 8)];
			}
		}
	}
}

typedef TextOptions = {
	var ?style:TextStyle;
	var ?delayTime:Float;
}

enum abstract TextStyle(FlxColor) from Int to Int {
	var ERROR:TextStyle = FlxColor.RED;
	var RIGHT:TextStyle = FlxColor.GREEN;
	var NORMAL:TextStyle = FlxColor.WHITE;
}
