package funkin.backend.scripting.annexes;

import funkin.backend.scripting.Script;
import hscript.Interp;
import hscript.Parser;
import hscript.Expr;
import hscript.customclass.CustomClassDecl;

@:allow(funkin.backend.scripting.annexes.AnnexManager)
final class Annex {
	private static var parser:Parser = new Parser();

	public var customClassesMap:Map<String, CustomClassDecl>;
	private var interp:Interp;

	private var packName:Null<String>;
	private var cwdPath:String;
	private var filesName:Array<String>;

	public function new(packName:Null<String>, filesName:Array<String>, ?cwdPath:String) {
		this.packName = packName;
		this.cwdPath = (cwdPath == null ? 'assets/${AnnexManager.yourDadPath}' : cwdPath);
		this.filesName = filesName;

		interp = zbInterp();
		customClassesMap = new Map<String, CustomClassDecl>();
	}

	public function execute() {
		var requested:Int = 0;
		for(file in filesName) {
			final path = '${cwdPath}${packName.replace(".", "/")}/${file}';
			if(AnnexManager.retrievalExtensions.contains(Path.extension(path)) && Assets.exists(path)) {
				final reClname = Path.withoutExtension(file);
				final origin = (packName == null ? reClname : '$packName.$reClname');
				interp.execute(parser.parseString(Assets.getText(path), origin));
				if(interp.allowStaticAccessClasses.length > requested) {
					for(diff in 0...Math.abs(interp.allowStaticAccessClasses.length - requested)) {
						final clName = interp.allowStaticAccessClasses[interp.allowStaticAccessClasses.length - (diff + 1)];
						if(clName != reClname) {
							customClassesMap.set('$origin.$clName', Interp.getCustomClass(clName));
						}else {
							customClassesMap.set(origin, Interp.getCustomClass(clName));
						}
					}

					requested = interp.allowStaticAccessClasses.length;
				}
			}
		}
	}

	private inline function zbInterp():Interp {
		var interp:Interp = new Interp();
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.staticVariables = Script.staticVariables;
		interp.errorHandler = _errorHandler;
		for(k=>e in Script.getDefaultVariables()) {
			interp.variables.set(k, e);
		}

		return interp;
	}

	@:noCompletion private function _errorHandler(error:Error) {
		var fileName = error.origin;
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, RED)
		], ERROR);

		//把这里原本的依托卸了
		#if mobile
		Main.instance.debugPrintLog.debugPrint(fn, {delayTime: 3.5, style: 0x00ff00});
		Main.instance.debugPrintLog.debugPrint(err, {delayTime: 3.5, style: 0xff0000});
		#end
	}
}