package funkin.options.keybinds;

import flixel.effects.FlxFlicker;
import funkin.backend.system.Controls;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;

class ChangeKeybindSubState extends MusicBeatSubstate {
	var callback:FlxKey->Void;
	var cancelCallback:Bool->Void;

	var stillPressed:Bool = true;
	public override function new(callback:FlxKey->Void, cancelCallback:Bool->Void) {
		this.callback = callback;
		this.cancelCallback = cancelCallback;
		super();
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (stillPressed && controls.ACCEPT)
			return;
		stillPressed = false;

		var gamepad:FlxGamepad = FlxG.gamepads.getByID(0);
		if((gamepad!=null && gamepad.justPressed.B)){
			close();	
			cancelCallback(true);
			return;
		}
		
		var key:FlxKey = FlxG.keys.firstJustPressed();
		if (cast(key, Int) <= 0) return;


		if (key == ESCAPE && !FlxG.keys.pressed.SHIFT) {
			close();	
			cancelCallback(false);
			return;
		}
		close();
		callback(key);
		return;
	}
}