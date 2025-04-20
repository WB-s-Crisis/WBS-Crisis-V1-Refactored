package funkin.backend.utils;

#if ALLOW_MULTITHREADING
import lime.system.ThreadPool;
import lime.system.WorkOutput;
class ThreadUtil {
	/**
	 * Creates a new Thread with an error handler.
	 * @param func Function to execute
	 * @param autoRestart Whenever the thread should auto restart itself after crashing.
	 */
	public static function createSafe(func:Void->Void, autoRestart:Bool = false) {
		if (autoRestart) {
			return sys.thread.Thread.create(function() {
				while(true) {
					try {
						func();
					} catch(e) {
						trace(e.details());
					}
				}
			});
		} else {
			return sys.thread.Thread.create(function() {
				try {
					func();
				} catch(e) {
					trace(e.details());
				}
			});
		}
	}
	
	public static function launchThreadPool(mainFunc:State->WorkOutput->Void, ?onComplete:Dynamic->Void, ?onProgress:Dynamic->Void, ?onError:Dynamic->Void, autoStart:Bool = true) {
		var threadPool:ThreadPool = new ThreadPool(0, CoolUtil.getCPUThreadsCount());
		
		threadPool.doWork.add(mainFunc);
		if(onComplete != null) threadPool.onComplete.add(onComplete);
		if(onProgress != null) threadPool.onProgress.add(onComplete);
		if(onError != null) threadPool.onError.add(onError);
		
		if(autoStart) threadPool.queue();
		
		return threadPool;
	}
}
#end