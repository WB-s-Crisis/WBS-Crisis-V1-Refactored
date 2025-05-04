package funkin.backend.shaders;

import haxe.Exception;
import hscript.IHScriptCustomBehaviour;
import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display3D.Program3D;
import funkin.backend.shaders.SourceShader;

import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.utils._internal.Log;
import openfl.display.BitmapData;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.ShaderInput;
import lime.utils.Float32Array;

class FunkinShader extends SourceShader implements IHScriptCustomBehaviour {
	private static var __instanceFields = Type.getInstanceFields(FunkinShader);

	public function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_${name}')) {
			return Reflect.getProperty(this, name);
		}
		if (!Reflect.hasField(data, name)) return null;
		var field = Reflect.field(data, name);
		var cl = Type.getClassName(Type.getClass(field));

		// little problem we are facing boys...

		// cant do "field is ShaderInput" because ShaderInput has the @:generic metadata
		// aka instead of ShaderInput<Float> it gets built as ShaderInput_Float
		// this should be fine tho because we check the class, and the fields dont vary based on the type

		// thanks for looking in the code cne fans :D!! -lunar

		if (cl.startsWith("openfl.display.ShaderParameter"))
			return (field.__length > 1) ? field.value : field.value[0];
		else if (cl.startsWith("openfl.display.ShaderInput"))
			return field.input;
		return field;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_${name}')) {
			Reflect.setProperty(this, name, val);
			return val;
		}

		if (!Reflect.hasField(data, name)) {
			Reflect.setField(data, name, val);
			return val;
		} else {
			var field = Reflect.field(data, name);
			var cl = Type.getClassName(Type.getClass(field));
			// cant do "field is ShaderInput" for some reason
			if (cl.startsWith("openfl.display.ShaderParameter")) {
				if (field.__length <= 1) {
					// that means we wait for a single number, instead of an array
					if (field.__isInt && !(val is Int)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Int');
						return null;
					} else
					if (field.__isBool && !(val is Bool)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Bool');
						return null;
					} else
					if (field.__isFloat && !(val is Float)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Float');
						return null;
					}
					return field.value = [val];
				} else {
					if (!(val is Array)) {
						throw new ShaderTypeException(name, Type.getClass(val), Array);
						return null;
					}
					return field.value = val;
				}
			} else if (cl.startsWith("openfl.display.ShaderInput")) {
				// shader input!!
				if (!(val is BitmapData)) {
					throw new ShaderTypeException(name, Type.getClass(val), BitmapData);
					return null;
				}
				field.input = cast val;
			}
		}

		return val;
	}
}
