package debug;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import openfl.text.TextField;
import openfl.text.TextFormat;
import haxe.Timer;
import cpp.vm.Gc;
import Type;

/**
 * Simple FPS Counter with Memory Usage and Debug Info
 */
class FPSCounter extends TextField
{
    public var currentFPS(default, null):Float;
    public var memory(get, never):Float;

    inline function get_memory():Float
        return Gc.memInfo64(Gc.MEM_INFO_USAGE);

    private var times:Array<Float>;
    private var fpsMultiplier:Float = 1.0;
    private var deltaTimeout:Float = 0.0;
    public var timeoutDelay:Float = 50;
    private var timeColor:Float = 0.0;

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
    {
        super();
        this.x = x;
        this.y = y;

        currentFPS = 0;
        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat("_sans", 14, color);
        autoSize = LEFT;
        multiline = true;
        text = "FPS: ";

        times = [];
    }

    override function __enterFrame(deltaTime:Float):Void
    {
        if (!ClientPrefs.data.showFPS || !visible) return;

        var now = Timer.stamp() * 1000;
        times.push(now);

        while (times.length > 0 && times[0] < now - 1000 / fpsMultiplier)
            times.shift();

        if (deltaTimeout < timeoutDelay)
        {
            deltaTimeout += deltaTime;
            return;
        }

        // Playback Rate / Trolling check
        if (Std.isOfType(FlxG.state, PlayState) && !PlayState.instance.trollingMode)
        {
            try fpsMultiplier = PlayState.instance.playbackRate;
            catch (e:Dynamic) fpsMultiplier = 1.0;
        }
        else fpsMultiplier = 1.0;

        currentFPS = Math.min(FlxG.drawFramerate, times.length) / fpsMultiplier;

        updateText();

        deltaTimeout = 0.0;
    }

    public dynamic function updateText():Void
    {
        text = "FPS: " + (ClientPrefs.data.ffmpegMode ? ClientPrefs.data.targetFPS : Math.round(currentFPS));

        if (ClientPrefs.data.ffmpegMode)
            text += " (Rendering Mode)";

        if (ClientPrefs.data.showMemory)
            text += "\nMemory: " + FlxStringUtil.formatBytes(memory);

        if (ClientPrefs.data.debugInfo)
        {
            text += '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}';
            if (FlxG.state.subState != null)
                text += '\nSubstate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';
        }

        if (ClientPrefs.data.rainbowFPS)
        {
            timeColor = (timeColor % 360.0) + (1.0 / (ClientPrefs.data.framerate / 120));
            textColor = FlxColor.fromHSB(timeColor, 1, 1);
        }
        else if (!ClientPrefs.data.ffmpegMode)
        {
            textColor = 0xFFFFFFFF;

            var halfFPS = ClientPrefs.data.framerate / 2;
            var thirdFPS = ClientPrefs.data.framerate / 3;
            var quarterFPS = ClientPrefs.data.framerate / 4;

            if (currentFPS <= halfFPS && currentFPS >= thirdFPS)
                textColor = 0xFFFFFF00; // Yellow
            else if (currentFPS <= thirdFPS && currentFPS >= quarterFPS)
                textColor = 0xFFFF8000; // Orange
            else if (currentFPS <= quarterFPS)
                textColor = 0xFFFF0000; // Red
        }
    }
}
