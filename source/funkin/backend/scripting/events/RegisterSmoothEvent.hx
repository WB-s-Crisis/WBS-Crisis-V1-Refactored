package funkin.backend.scripting.events;

import funkin.game.PlayState.PlayStateTransitionData;

final class RegisterSmoothEvent extends CancellableEvent {
  public var smoothTransition:PlayStateTransitionData;
  public var skipTransIn:Bool;
  public var skipTransOut:Bool;

  @:dox(hide) public var skipTransCancelled:Bool = false;
  @:dox(hide) public function cancelSkipTrans():Void {
    skipTransCancelled = true;
  }
}
