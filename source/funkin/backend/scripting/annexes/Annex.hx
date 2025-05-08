package funkin.backend.scripting.annexes;

import haxe.io.Path;
import funkin.backend.scripting.Script;
import hscript.Interp;
import hscript.Parser;
import hscript.Expr;
import hscript.customclass.CustomClassDecl;

@:allow(funkin.backend.scripting.annexes.AnnexManager)
final class Annex {
	private static var parser:Parser = new Parser();

	public var customClassesMap:Map<String, CustomClassDecl>;
	public var allowStaticAccessClasses:Array<String>;
	private var interps:Array<Interp>;

	private var packName:Null<String>;
	private var cwdPath:String;
	private var filesName:Array<String>;

	public function new(packName:Null<String>, filesName:Array<String>, ?cwdPath:String) {
		this.packName = packName;
		this.cwdPath = (cwdPath == null ? 'assets/${AnnexManager.yourDadPath}' : cwdPath);
		this.filesName = filesName;

		interps = new Array<Interp>();
		allowStaticAccessClasses = new Array<String>();
		customClassesMap = new Map<String, CustomClassDecl>();
	}

	public function execute() {
		var requested:Int = 0;
		for(file in filesName) {
			final path = '${cwdPath}${packName.replace(".", "/")}/${file}';
			if(AnnexManager.retrievalExtensions.contains(Path.extension(path)) && Assets.exists(path)) {
				final reClname = Path.withoutExtension(file);
				final origin = (packName == null ? reClname : '$packName.$reClname');

				var expr = null;
				if((expr = parse(Assets.getText(path), origin)) == null) continue;

				var interp = zbInterp();
				interp.execute(expr);
				if(allowStaticAccessClasses.length > requested) {
					for(diff in 0...(allowStaticAccessClasses.length - requested)) {
						final clName = allowStaticAccessClasses[allowStaticAccessClasses.length - (diff + 1)];
						if(clName != reClname) {
							customClassesMap.set('$origin.$clName', Interp.getCustomClass(clName));
						}else {
							customClassesMap.set(origin, Interp.getCustomClass(clName));
						}
					}

					requested = allowStaticAccessClasses.length;
				}
			}
		}
	}

	private function parse(code:String, origin:String) {
		var expr:Expr = null;
		try {
			if (code != null && code.trim() != "")
				expr = parser.parseString(code, origin);
		} catch(e:Error) {
			_errorHandler(e);
		} catch(e) {
			_errorHandler(new Error(ECustom(e.toString()), 0, 0, origin, 0));
		}

		return expr;
	}

	private inline function zbInterp():Interp {
		if(interps == null || allowStaticAccessClasses == null) return null;

		var interp:Interp = new Interp();
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.allowStaticAccessClasses = allowStaticAccessClasses;
		interp.staticVariables = Script.staticVariables;
		interp.errorHandler = _errorHandler;
		interp.importFailedCallback = importFailedCallback;
		for(k=>e in Script.getDefaultVariables()) {
			interp.variables.set(k, e);
		}

		return interp;
	}

	private function importFailedCallback(cl:Array<String>, ?n:String) {
		final clPath:String = cl.join(".");
		for(byd in AnnexManager.annexes) {
			if(byd.customClassesMap.exists(clPath)) {
				if(byd.customClassesMap.exists(clPath.substr(0, clPath.lastIndexOf(".")))) {
					if(n != null) {
						@:privateAccess Interp._customClassAliases.set(n, byd.customClassesMap.get(clPath).classDecl.name);
						allowStaticAccessClasses.push(n);
						return true;
					}

					allowStaticAccessClasses.push(byd.customClassesMap.get(clPath).classDecl.name);
				}else {
					for(k=>v in byd.customClassesMap) {
						if(k.substr(0, k.lastIndexOf(".")) == clPath) {
							allowStaticAccessClasses.push(v.classDecl.name);
						}else if(k == clPath) {
							if(n != null) {
								@:privateAccess Interp._customClassAliases.set(n, v.classDecl.name);
								allowStaticAccessClasses.push(n);
							} else allowStaticAccessClasses.push(v.classDecl.name);
						}
					}
				}

				return true;
			}
		}

		return false;
	}

	private function _errorHandler(error:Error) {
		var fileName = error.origin;
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, RED)
		], ERROR);

		#if mobile
		Main.instance.debugPrintLog.debugPrint(fn, {delayTime: 3.5, style: 0x00ff00});
		Main.instance.debugPrintLog.debugPrint(err, {delayTime: 3.5, style: 0xff0000});
		#end
	}
}