package funkin.backend.system;

import funkin.backend.system.framerate.Framerate;
import flixel.FlxGame;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;
	public override function switchState() {
		if(Framerate.instance!=null)
			Framerate.instance.resetTextField();
		
		super.switchState();
		// draw once to put all images in gpu then put the last update time to now to prevent lag spikes or whatever
		draw();
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	public override function onEnterFrame(t) {
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);

		#if !web
		if (FlxG.keys.justPressed.F11)
			FlxG.fullscreen = !FlxG.fullscreen;
		#end
	}
}