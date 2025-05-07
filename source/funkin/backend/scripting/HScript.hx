package funkin.backend.scripting;

import haxe.io.Path;
import hscript.Expr.Error;
import hscript.Parser;
import openfl.Assets;
import hscript.*;
import funkin.backend.scripting.annexes.AnnexManager;

class HScript extends Script {
	public var interp:Interp;
	public var parser:Parser;
	public var expr:Expr;
	public var code:String = null;
	
	public var lastThrow:Error = null;
	
	//public var folderlessPath:String;
	var __importedPaths:Array<String>;

	public static function initParser() {
		var parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		parser.preprocesorValues = Script.getDefaultPreprocessors();
		return parser;
	}

	public override function onCreate(path:String) {
		super.onCreate(path);

		interp = new Interp();

		try {
			if(Assets.exists(rawPath)) code = Assets.getText(rawPath);
		} catch(e) Logs.trace('Error while reading $path: ${Std.string(e)}', ERROR);

		parser = initParser();
		//folderlessPath = Path.directory(path);
		__importedPaths = [path];

		interp.errorHandler = _errorHandler;
		interp.importFailedCallback = importFailedCallback;
		interp.staticVariables = Script.staticVariables;
		interp.allowStaticVariables = interp.allowPublicVariables = true;

		interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
			var v:String = Std.string(args.shift());
			for (a in args) v += ", " + Std.string(a);
			this.trace(v);
		}));

		interp.variables.set("debugPrint", Main.instance.debugPrintLog.debugPrint);

		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.call("onScriptCreated", [this, "hscript"]);
		#end
		loadFromString(code);
	}

	public override function loadFromString(code:String) {
		try {
			if (code != null && code.trim() != "")
				expr = parser.parseString(code, fileName);
		} catch(e:Error) {
			_errorHandler(e);
		} catch(e) {
			_errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
		}

		return this;
	}

	private function importFailedCallback(cl:Array<String>, ?n:String) {
		final clPath:String = cl.join(".");
		for(byd in AnnexManager.annexes) {
			if(byd.customClassesMap.exists(clPath)) {
				if(byd.customClassesMap.exists(clPath.substr(0, clPath.lastIndexOf(".")))) {
					if(n != null) {
						@:privateAccess Interp._customClassAliases.set(n, byd.customClassesMap.get(clPath).classDecl.name);
						interp.allowStaticAccessClasses.push(n);
						return true;
					}

					interp.allowStaticAccessClasses.push(byd.customClassesMap.get(clPath).classDecl.name);
				}else {
					for(k=>v in byd.customClassesMap) {
						if(k.substr(0, k.lastIndexOf(".")) == clPath) {
							interp.allowStaticAccessClasses.push(v.classDecl.name);
						}else if(k == clPath) {
							if(n != null) {
								@:privateAccess Interp._customClassAliases.set(n, k.classDecl.name);
								interp.allowStaticAccessClasses.push(n);
								return true;
							}

							interp.allowStaticAccessClasses.push(v.classDecl.name);
						}
					}
				}

				return true;
			}
		}

		return false;
	}

	private function _errorHandler(error:Error) {
		lastThrow = error;

		var fileName = error.origin;
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
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

	public override function setParent(parent:Dynamic) {
		interp.scriptObject = parent;
	}

	public override function onLoad() {
		@:privateAccess
		interp.execute(parser.mk(EBlock([]), 0, 0));
		if (expr != null) {
			interp.execute(expr);
			#if GLOBAL_SCRIPT
			funkin.backend.scripting.GlobalScript.call("onScriptLoaded", [this, "hscript"]);
			#end
			call("new", []);
		}
	}

	public override function reload() {
		// save variables

		interp.allowStaticVariables = interp.allowPublicVariables = false;
		interp.allowStaticAccessClasses = [];
		var savedVariables:Map<String, Dynamic> = [];
		for(k=>e in interp.variables) {
			if (!Reflect.isFunction(e)) {
				savedVariables[k] = e;
			}
		}
		var oldParent = interp.scriptObject;
		onCreate(path);

		for(k=>e in Script.getDefaultVariables(this))
			set(k, e);

		load();
		setParent(oldParent);

		for(k=>e in savedVariables)
			interp.variables.set(k, e);

		interp.allowStaticVariables = interp.allowPublicVariables = true;
	}

	private override function onCall(funcName:String, parameters:Array<Dynamic>):Dynamic {
		if (interp == null) return null;
		if (!interp.variables.exists(funcName)) return null;

		var func = interp.variables.get(funcName);
		if (func != null && Reflect.isFunction(func)) {
			try {
				return Reflect.callMethod(null, func, parameters);
			} catch(e:haxe.Exception) {
				_errorHandler(new Error(ECustom(e.message), 0, 0, fileName, 0));
			}
		}

		return null;
	}

	public override function get(val:String):Dynamic {
		return interp.variables.get(val);
	}

	public override function set(val:String, value:Dynamic) {
		interp.variables.set(val, value);
	}

	public override function trace(v:Dynamic) {
		var posInfo = interp.posInfos();
		Logs.traceColored([
			Logs.logText('${fileName}:${posInfo.lineNumber}: ', GREEN),
			Logs.logText(Std.isOfType(v, String) ? v : Std.string(v))
		], TRACE);
	}

	public override function setPublicMap(map:Map<String, Dynamic>) {
		this.interp.publicVariables = map;
	}
}
