package funkin.backend.scripting.events;

import funkin.backend.scripting.events.PlayAnimEvent.PlayAnimContext;

final class TryDanceEvent extends CancellableEvent {
	public var lastAnimContext:PlayAnimContext;

	public var singHoldTime:Float;

	@:dox(hide) public var singAnimCancelled:Bool = false;
	@:dox(hide) public var danceAnimCancelled:Bool = false;
	@:dox(hide) public var lockAnimCancelled:Bool = false;
	@:dox(hide) public var defaultAnimCancelled:Bool = false;

	@:dox(hide) public function cancelTrySing() {singAnimCancelled = true;}
	@:dox(hide) public function cancelTryDance() {danceAnimCancelled = true;}
	@:dox(hide) public function cancelTryLock() {lockAnimCancelled = true;}
	@:dox(hide) public function cancelTryDefAnim() {defaultAnimCancelled = true;}
}
