package funkin.extra;

import flixel.math.FlxRect;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

//懒得自个写一个了，反正跟牢马差不多一个款式的，以后优化
class PsychBar extends FlxTypedSpriteGroup<FlxSkewedSprite>
{
	public var leftBar:FlxSkewedSprite;
	public var rightBar:FlxSkewedSprite;
	public var bg:FlxSkewedSprite;
	public var valueFunction:Void->Float = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, ?image:String, width:Int = 1, height:Int = 1, valueFunction:Void->Float = null, boundX:Float = 0, boundY:Float = 1, offsetX:Float = 0, offsetY:Float = 0, offsetWidth:Int = 0, offsetHeight:Int = 0)
	{
		super(x, y);
		
		this.valueFunction = valueFunction;
		setBounds(boundX, boundY);
		barOffset.set(offsetX, offsetY);
		
		final condition = image != null && Assets.exists(image);
		if(condition) {
			bg = new FlxSkewedSprite();
			bg.loadGraphic(image);
			bg.antialiasing = Options.antialiasing;
			barWidth = Std.int(bg.width - offsetWidth);
			barHeight = Std.int(bg.height - offsetHeight);
		}else {
			barWidth = Std.int(width - offsetWidth);
			barHeight = Std.int(height - offsetHeight);
		}

		leftBar = new FlxSkewedSprite();
		leftBar.makeGraphic(Std.int(barWidth), Std.int(barHeight), FlxColor.WHITE);
		//leftBar.color = FlxColor.WHITE;
		leftBar.antialiasing = antialiasing = Options.antialiasing;

		rightBar = new FlxSkewedSprite();
		rightBar.makeGraphic(Std.int(barWidth), Std.int(barHeight), FlxColor.WHITE);
		rightBar.color = FlxColor.BLACK;
		rightBar.antialiasing = Options.antialiasing;

		add(leftBar);
		add(rightBar);
		if(condition) add(bg);
		regenerateClips();
	}

	public var enabled:Bool = true;
	override function update(elapsed:Float) {
		if(!enabled)
		{
			super.update(elapsed);
			return;
		}

		if(valueFunction != null)
		{
			var value:Null<Float> = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
			percent = (value != null ? value : 0);
		}
		else percent = 0;
		super.update(elapsed);
	}
	
	public function setBounds(min:Float, max:Float)
	{
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(left:FlxColor = null, right:FlxColor = null)
	{
		if (left != null)
			leftBar.color = left;
		if (right != null)
			rightBar.color = right;
	}

	public function updateBar()
	{
		if(leftBar == null || rightBar == null) return;

		leftBar.setPosition(this.x, this.y);
		rightBar.setPosition(this.x, this.y);

		var leftSize:Float = 0;
		if(leftToRight) leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		barCenter = leftBar.x + leftSize + barOffset.x;

		// flixel is retarded
		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}

	public function regenerateClips()
	{
		if(leftBar != null)
		{
			leftBar.setGraphicSize(Std.int(barWidth), Std.int(barHeight));
			leftBar.updateHitbox();
			leftBar.clipRect = new FlxRect(0, 0, Std.int(barWidth), Std.int(barHeight));
		}
		if(rightBar != null)
		{
			rightBar.setGraphicSize(Std.int(barWidth), Std.int(barHeight));
			rightBar.updateHitbox();
			rightBar.clipRect = new FlxRect(0, 0, Std.int(barWidth), Std.int(barHeight));
		}
		updateBar();
	}

	private function set_percent(value:Float)
	{
		var doUpdate:Bool = false;
		if(value != percent) doUpdate = true;
		percent = value;

		if(doUpdate) updateBar();
		return value;
	}

	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}
}