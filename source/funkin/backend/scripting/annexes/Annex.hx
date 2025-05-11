package funkin.backend.scripting.annexes;

import haxe.io.Path;
import funkin.backend.scripting.Script;
import hscript.Interp;
import hscript.Parser;
import hscript.Expr;
import hscript.Tools.HScriptEnum;
import hscript.customclass.CustomClassDecl;

@:allow(funkin.backend.scripting.annexes.AnnexManager)
final class Annex {
	public var allowStaticAccessTypes:Array<String>;
	public var modules:Map<String, AnnexModule>;
	public var packName:Null<String>;

	private var cwdPath:String;
	private var filesName:Array<String>;

	public function new(packName:Null<String>, filesName:Array<String>, ?cwdPath:String) {
		this.packName = packName;
		this.cwdPath = (cwdPath == null ? 'assets/${AnnexManager.yourDadPath}' : cwdPath);
		this.filesName = filesName;

		modules = new Map<String, AnnexModule>();
		allowStaticAccessTypes = new Array<String>();
		customClassesMap = new Map<String, CustomClassDecl>();
	}

	public function execute() {
		var requested:Int = 0;
		for(file in filesName) {
			final path = '${cwdPath}${packName.replace(".", "/")}/${file}';
			if(AnnexManager.retrievalExtensions.contains(Path.extension(path)) && Assets.exists(path)) {
				final reClname = Path.withoutExtension(file);
				final origin = (packName == null ? reClname : '$packName.$reClname');

				var ass:AnnexModule = new AnnexModule(this, Assets.getText(path), origin);
				modules.set(origin, ass);
				ass.execute();
			}
		}
	}
}

final class AnnexModule {
	public var interp:Interp;
	public var parser:Parser;

	public var moduleName(get, never):String;
	inline function get_moduleName():String {
		final index:Int = (origin.lastIndexOf(".") > -1 ? origin.lastIndexOf(".") + 1 : 0);
		return origin.substr(index);
	}

	public var customClasses:Map<String, CustomClassDecl>;
	public var customEnums:Map<String, HScriptEnum>;

	private var dad:Annex;
	private var code:String;
	private var origin:String;
	private var expr:Expr;

	public function new(parent:Annex, code:String, origin:String) {
		dad = parent;
		this.code = code;
		this.origin = origin;

		initVars();
	}

	public function execute() {
		parse();

		if(this.expr != null) {
			interp.execute(expr);

			for(cls in interp.allowStaticAccessClasses) {
				if(Interp.customClassExist(cls)) {
					customClasses.set(cls, Interp.getCustomClass(cls));
					if(!dad.allowStaticAccessTypes.contains(cls))
						dad.allowStaticAccessTypes.push(cls);
				}
			}
			for(name in customEnums.keys()) {
				if(!dad.allowStaticAccessTypes.contains(name))
					dad.allowStaticAccessTypes.push(name);
			}
		}
	}

	private function initVars() {
		customClasses = new Map<String, CustomClassDecl>();
		customEnums = new Mao<String, HScriptEnum>();

		interp = new Interp();
		interp.customEnums = this.customEnums;
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.staticVariables = Script.staticVariables;
		interp.errorHandler = _errorHandler;
		interp.importFailedCallback = importFailedCallback;
		for(k=>e in Script.getDefaultVariables()) {
			interp.variables.set(k, e);
		}

		parser = new Parser();
		parser.allowTypes = parser.allowMetadata = parser.allowJSON = true;
	}

	private function parse() {
		try {
			if (code != null && code.trim() != "")
				this.expr = parser.parseString(code, origin);
		} catch(e:Error) {
			_errorHandler(e);
		} catch(e) {
			_errorHandler(new Error(ECustom(e.toString()), 0, 0, origin, 0));
		}
	}

	@:noCompletion private function importFailedCallback(cl:Array<String>, ?n:String) {
		final path:String = cl.join(".");
		for(byd in AnnexManager.annexes) {
			if(byd.packName != null) {
				if(path.indexOf(byd.packName) == 0) {
					final module = path.substr(byd.packName.length + 1).split(".");
					if(byd.modules.exists(module[0])) {
						final inModule = byd.modules.get(module[0]);
						if(module.length > 1) {
							if(inModule.customClasses.exists(module[1])) {
								if(n != null) {
									@:privateAccess Interp._customClassAliases.set(n, module[1]);
									interp.allowStaticAccessClasses.push(n);
								} else interp.allowStaticAccessClasses.push(module[1]);

								return true;
							} else if(inModule.customEnums.exists(module[1])) {
								interp.set((n != null ? n : module[1]), inModule.customEnums.get(module[1]));
								return true;
							}
						} else if(module.length == 1) {
							for(key in inModule.customClasses.keys()) {
								if(module[0] == key && n != null) {
									@:privateAccess Interp._customClassAliases.set(n, key);
									interp.allowStaticAccessClasses.push(n);

									continue;
								}

								interp.allowStaticAccessClasses.push(key);
							}
							for(key=>value in inModule.customEnums) {
								if(module[0] == key && n != null) {
									interp.customEnums.set(n, value);

									continue;
								}

								interp.customEnums.set(key, value);
							}

							return true;
						}
					}
				}
			} else {
				final module = cl;
				if(byd.modules.exists(module[0])) {
					final inModule = byd.modules.get(module[0]);
					if(module.length > 1) {
						if(inModule.customClasses.exists(module[1])) {
							if(n != null) {
								@:privateAccess Interp._customClassAliases.set(n, module[1]);
								interp.allowStaticAccessClasses.push(n);
							} else interp.allowStaticAccessClasses.push(module[1]);

							return true;
						} else if(inModule.customEnums.exists(module[1])) {
							interp.set((n != null ? n : module[1]), inModule.customEnums.get(module[1]));
							return true;
						}
					} else if(module.length == 1) {
						for(key in inModule.customClasses.keys()) {
							if(module[0] == key && n != null) {
								@:privateAccess Interp._customClassAliases.set(n, key);
								interp.allowStaticAccessClasses.push(n);

								continue;
							}

							interp.allowStaticAccessClasses.push(key);
						}
						for(key=>value in inModule.customEnums) {
							if(module[0] == key && n != null) {
								interp.customEnums.set(n, value);

								continue;
							}

							interp.customEnums.set(key, value);
						}

						return true;
					}
				}
			}
		}

		return false;
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

		#if mobile
		Main.instance.debugPrintLog.debugPrint(fn, {delayTime: 3.5, style: 0x00ff00});
		Main.instance.debugPrintLog.debugPrint(err, {delayTime: 3.5, style: 0xff0000});
		#end
	}
}