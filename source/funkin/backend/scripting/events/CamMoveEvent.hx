package funkin.backend.scripting.events;

import funkin.game.StrumLine;
import flixel.math.FlxPoint;

final class CamMoveEvent extends CancellableEvent {
	/**
	 * Final camera position.
	 */
	public var position:FlxPoint;

	/**
	 * Currently focused strumline.
	 */
	public var strumLine(get, set):StrumLine;

	public var strumLines:Array<StrumLine>;

	/**
	 * Number of focused characters
	 */
	public var focusedCharacters:Int;

	public var duetCamera:Bool = false;

	public var duetRatio:Float = 0.5;

	private inline function get_strumLine()
		return strumLines[0];
	private function set_strumLine(st:StrumLine) {
		strumLines = [st];
		return st;
	}
}