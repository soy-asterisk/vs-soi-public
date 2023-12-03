package funkin.game;

import flixel.math.FlxPoint;
import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.backend.scripting.events.*;
import funkin.backend.system.Conductor;
import funkin.backend.chart.ChartData;
import funkin.backend.system.Controls;
import flixel.tweens.FlxTween;

class StrumLine extends FlxTypedGroup<Strum> {
	/**
	 * Signal that triggers whenever a note is hit. Similar to onPlayerHit and onDadHit, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onHit.add(function(e:NoteHitEvent) {});`
	 */
	public var onHit:FlxTypedSignal<NoteHitEvent->Void> = new FlxTypedSignal<NoteHitEvent->Void>();
	/**
	 * Signal that triggers whenever a note is missed. Similar to onPlayerMiss, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onMiss.add(function(e:NoteMissEvent) {});`
	 */
	public var onMiss:FlxTypedSignal<NoteMissEvent->Void> = new FlxTypedSignal<NoteMissEvent->Void>();
	/**
	 * Signal that triggers whenever a note is being updated. Similar to onNoteUpdate, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onNoteUpdate.add(function(e:NoteUpdateEvent) {});`
	 */
	public var onNoteUpdate:FlxTypedSignal<NoteUpdateEvent->Void> = new FlxTypedSignal<NoteUpdateEvent->Void>();
	/**
	 * Signal that triggers whenever a note is being updated. Similar to onNoteUpdate, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onNoteUpdate.add(function(e:NoteUpdateEvent) {});`
	 */
	public var onNoteDelete:FlxTypedSignal<SimpleNoteEvent->Void> = new FlxTypedSignal<SimpleNoteEvent->Void>();
	/**
	 * Array containing all of the characters "attached" to those strums.
	 */
	public var characters:Array<Character>;
	/**
	 * Whenever this strumline is controlled by cpu or not.
	 */
	public var cpu(default, set):Bool = false;
	/**
	 * Whenever this strumline is from the opponent side or the player side.
	 */
	public var opponentSide:Bool = false;
	/**
	 * Controls assigned to this strumline.
	 */
	public var controls:Controls = null;
	/**
	 * Chart JSON data assigned to this StrumLine (Codename format)
	 */
	public var data:ChartStrumLine = null;
	/**
	 * Whenever Ghost Tapping is enabled.
	 */
	@:isVar public var ghostTapping(get, set):Null<Bool> = null;
	/**
	 * Group of all of the notes in this strumline. Using `forEach` on this group will only loop through the first notes for performance reasons.
	 */
	public var notes:NoteGroup;
	/**
	 * Whenever alt animation is enabled on this strumline.
	 */
	public var altAnim(get, set):Bool;
	/**
	 * Which animation suffix on characters that should be used when hitting notes.
	 */
	public var animSuffix(default, set):String = "";
	/**
	 * TODO: Write documention about this being a variable that can help when making multi key
	 */
	public var strumAnimPrefix = ["left", "down", "up", "right"];

	public var extra:Map<String, Dynamic> = [];
	
	@:isVar public var botplay(get, set):Null<Bool> = null;

	private function get_ghostTapping() {
		if (this.ghostTapping != null) return this.ghostTapping;
		if (PlayState.instance != null) return PlayState.instance.ghostTapping;
		return false;
	}

	private inline function set_ghostTapping(b:Null<Bool>):Null<Bool>
		return this.ghostTapping = b;

	private function get_botplay() {
		if (this.botplay != null) return this.botplay;
		if (PlayState.instance != null) return PlayState.instance.botplay;
		return false;
	}

	private inline function set_botplay(b:Null<Bool>):Null<Bool> {
		return this.botplay = b;
	}

	private var startingPos:FlxPoint = FlxPoint.get(0,0);
	private var strumScale:Float = 1;

	public function new(characters:Array<Character>, startingPos:FlxPoint, strumScale:Float, cpu:Bool = false, opponentSide:Bool = true, ?controls:Controls) {
		super();
		this.characters = characters;
		this.startingPos = startingPos;
		this.strumScale = strumScale;
		this.cpu = cpu;
		this.opponentSide = opponentSide;
		this.controls = controls;
		this.notes = new NoteGroup();
	}

	public function generate(strumLine:ChartStrumLine, ?startTime:Float) {
		// TODO: implement double generate call support if needed

		var total = 0;
		if (strumLine.notes != null) for(note in strumLine.notes) {
			if (startTime != null && startTime > note.time)
				continue;

			total++;

			if (note.sLen > Conductor.stepCrochet * 0.75) {
				var len:Float = note.sLen;
				while(len > 10) {
					total++;
					len -= Math.min(len, Conductor.stepCrochet);
				}
			}
		}

		notes.preallocate(total);

		var il = 0;

		var prev:Note = null;

		if (strumLine.notes != null) for(note in strumLine.notes) {
			if (startTime != null && startTime > note.time)
				continue;

			notes.members[total-(il++)-1] = prev = new Note(this, note, false, prev);

			if (note.sLen > Conductor.stepCrochet * 0.75) {
				var len:Float = note.sLen;
				var curLen:Float = 0;
				while(len > 10) {
					curLen = Math.min(len, Conductor.stepCrochet);
					notes.members[total-(il++)-1] = prev = new Note(this, note, true, curLen, note.sLen - len, prev);
					len -= curLen;
				}
			}
		}
		notes.sortNotes();
	}

	public override function update(elapsed:Float) {
		for(s in members) s.botplay = botplay;
		super.update(elapsed);
		notes.update(elapsed);
	}

	public override function draw() {
		super.draw();
		notes.cameras = cameras;
		notes.draw();
	}

	public inline function updateNotes() {
		notes.forEach(updateNote);
	}

	var __updateNote_strum:Strum;
	public function updateNote(daNote:Note) {
		__updateNote_strum = members[daNote.noteData];
		if (__updateNote_strum == null) return;

		PlayState.instance.__updateNote_event.recycle(daNote, FlxG.elapsed, __updateNote_strum);
		onNoteUpdate.dispatch(PlayState.instance.__updateNote_event);
		if (PlayState.instance.__updateNote_event.cancelled) return;

		if (PlayState.instance.__updateNote_event.__updateHitWindow) {
			daNote.canBeHit = (daNote.strumTime > Conductor.songPosition - (PlayState.instance.hitWindow * daNote.latePressWindow)
				&& daNote.strumTime < Conductor.songPosition + (PlayState.instance.hitWindow * daNote.earlyPressWindow));

			if (daNote.strumTime < Conductor.songPosition - PlayState.instance.hitWindow && !daNote.wasGoodHit)
				daNote.tooLate = true;
		}

		if ((cpu || botplay) && PlayState.instance.__updateNote_event.__autoCPUHit && !daNote.wasGoodHit && daNote.strumTime < Conductor.songPosition) PlayState.instance.goodNoteHit(this, daNote);

		if (daNote.wasGoodHit && daNote.isSustainNote && daNote.strumTime + (daNote.sustainLength) < Conductor.songPosition) {
			deleteNote(daNote);
			return;
		}

		if (daNote.tooLate && !(cpu || botplay)) {
			PlayState.instance.noteMiss(this, daNote);
			return;
		}


		if (PlayState.instance.__updateNote_event.strum == null) return;

		if (PlayState.instance.__updateNote_event.__reposNote) PlayState.instance.__updateNote_event.strum.updateNotePosition(daNote);
		if (daNote.isSustainNote)
			daNote.updateSustain(PlayState.instance.__updateNote_event.strum);
	}

	var __funcsToExec:Array<Note->Void> = [];
	var __pressed:Array<Bool> = [];
	var __justPressed:Array<Bool> = [];
	var __justReleased:Array<Bool> = [];
	var __notePerStrum:Array<Note> = [];

	function __inputProcessPressed(note:Note) {
		if (__pressed[note.strumID] && note.isSustainNote && note.canBeHit && !note.wasGoodHit) {
			PlayState.instance.goodNoteHit(this, note);
		}
	}
	function __inputProcessJustPressed(note:Note) {
		if (__justPressed[note.strumID] && !note.isSustainNote && !note.wasGoodHit && note.canBeHit) {
			if (__notePerStrum[note.strumID] == null) 											__notePerStrum[note.strumID] = note;
			else if (Math.abs(__notePerStrum[note.strumID].strumTime - note.strumTime) <= 2)  	deleteNote(note);
			else if (note.strumTime < __notePerStrum[note.strumID].strumTime)					__notePerStrum[note.strumID] = note;
		}
	}
	public function updateInput(id:Int = 0) {
		updateNotes();

		if (cpu || botplay) return;

		__funcsToExec.clear();
		__pressed.clear();
		__justPressed.clear();
		__justReleased.clear();

		for(s in members) {
			__pressed.push(s.__getPressed(this));
			__justPressed.push(s.__getJustPressed(this));
			__justReleased.push(s.__getJustReleased(this));
		}

		var event = PlayState.instance.scripts.event("onInputUpdate", EventManager.get(InputSystemEvent).recycle(__pressed, __justPressed, __justReleased, this, id));
		if (event.cancelled) return;

		__pressed = CoolUtil.getDefault(event.pressed, []);
		__justPressed = CoolUtil.getDefault(event.justPressed, []);
		__justReleased = CoolUtil.getDefault(event.justReleased, []);

		__notePerStrum = cast new haxe.ds.Vector(members.length);//[for(_ in 0...members.length) null];


		if (__pressed.contains(true)) {
			for(c in characters)
				if (c.lastAnimContext != DANCE)
					c.__lockAnimThisFrame = true;

			__funcsToExec.push(__inputProcessPressed);
		}
		if (__justPressed.contains(true))
			__funcsToExec.push(__inputProcessJustPressed);

		if (__justReleased.contains(true) && !__pressed.contains(true)) {
			for(c in characters)
				if (c.lastAnimContext != DANCE)
					c.__lockAnimThisFrame = false;
		}

		if (__funcsToExec.length > 0) {
			notes.forEachAlive(function(note:Note) {
				for(e in __funcsToExec) if (e != null) e(note);
			});
		}

		if (!ghostTapping) for(k=>pr in __justPressed) if (pr && __notePerStrum[k] == null) {
			// FUCK YOU
			PlayState.instance.noteMiss(this, null, k, ID);
		}
		for(e in __notePerStrum) if (e != null) PlayState.instance.goodNoteHit(this, e);

		forEach(function(str:Strum) {
			str.updatePlayerInput(str.__getPressed(this), str.__getJustPressed(this), str.__getJustReleased(this));
		});
		PlayState.instance.scripts.call("onPostInputUpdate");
	}

	public inline function addHealth(health:Float)
		PlayState.instance.health += health * (opponentSide ? -1 : 1);

	public inline function generateStrums(amount:Int = 4) {
		for (i in 0...amount)
			add(createStrum(i));
	}

	override function destroy() {
		super.destroy();
		if(startingPos != null)
			startingPos.put();
	}

	/**
	 * Creates a strum and returns the created strum (needs to be added manually).
	 * @param i Index of the strum
	 * @param animPrefix (Optional) Animation prefix (`left` = `arrowLEFT`, `left press`, `left confirm`).
	 */
	public function createStrum(i:Int, ?animPrefix:String) {
		if (animPrefix == null)
			animPrefix = strumAnimPrefix[i % strumAnimPrefix.length];
		var babyArrow:Strum = new Strum(startingPos.x + ((Note.swagWidth * strumScale) * i), startingPos.y);
		babyArrow.ID = i;
		
		if(data.scrollSpeed != null)
			babyArrow.scrollSpeed = data.scrollSpeed;
		
		var event = PlayState.instance.scripts.event("onStrumCreation", EventManager.get(StrumCreationEvent).recycle(babyArrow, PlayState.instance.strumLines.members.indexOf(this), i, animPrefix));

		if (!event.cancelled) {
			babyArrow.frames = Paths.getFrames(event.sprite);
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.antialiasing = true;
			babyArrow.setGraphicSize(Std.int((babyArrow.width * 0.7) * strumScale));

			babyArrow.animation.addByPrefix('static', 'arrow${event.animPrefix.toUpperCase()}');
			babyArrow.animation.addByPrefix('pressed', '${event.animPrefix} press', 24, false);
			babyArrow.animation.addByPrefix('confirm', '${event.animPrefix} confirm', 24, false);
		}

		babyArrow.cpu = cpu;
		babyArrow.updateHitbox();
		babyArrow.scrollFactor.set();

		if (event.__doAnimation)
		{
			var scrollValue:Int = (PlayState.instance!=null && PlayState.instance.downscroll)?-10:10;
			babyArrow.y -= scrollValue;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + scrollValue, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
		}
		babyArrow.playAnim('static');

		insert(i, babyArrow);

		PlayState.instance.scripts.event("onPostStrumCreation", event);

		return babyArrow;
	}

	/**
	 * Deletes a note from this strumline.
	 * @param note Note to delete
	 */
	public function deleteNote(note:Note) {
		if (note == null) return;
		var event:SimpleNoteEvent = EventManager.get(SimpleNoteEvent).recycle(note);
		onNoteDelete.dispatch(event);
		if (!event.cancelled) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	/**
	 * SETTERS & GETTERS
	 */
	#if REGION
	private inline function set_cpu(b:Bool):Bool {
		for(s in members)
			if (s != null)
				s.cpu = b;
		return cpu = b;
	}
	private inline function set_animSuffix(str:String):String {
		for(s in members)
			if (s != null)
				s.animSuffix = str;
		return animSuffix = str;
	}
	private inline function set_altAnim(b:Bool):Bool {
		animSuffix = b ? "-alt" : "";
		return b;
	}
	private inline function get_altAnim():Bool {
		return animSuffix == "-alt";
	}
	#end
}