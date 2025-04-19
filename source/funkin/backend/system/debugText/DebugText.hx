package funkin.backend.system.debugText;

import openfl.text.TextField;

/**
 * e......只是图个方便罢了
 */
class DebugText extends TextField {
    public var ID:Int = 0;
    public var delayTime:Float = 1;
    public var lastTime:Float = Math.NEGATIVE_INFINITY;
    
    public function new(id:Int, ?delayTime:Float) {
        super();
        ID = id;

        if(delayTime != null) {
            this.delayTime = delayTime;
        }
    }
}
