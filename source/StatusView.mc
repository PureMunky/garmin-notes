import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

//! Brief feedback message. Uses the native toast when the device has one,
//! otherwise a full-screen message that dismisses itself after 2 seconds.
class StatusView extends WatchUi.View {
    private var _message as String;
    private var _timer as Timer.Timer?;

    static function show(message as String) as Void {
        if (WatchUi has :showToast) {
            WatchUi.showToast(message, null);
        } else {
            var v = new StatusView(message);
            WatchUi.pushView(v, new StatusDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function initialize(message as String) {
        View.initialize();
        _message = message;
    }

    function onShow() as Void {
        var t = new Timer.Timer();
        t.start(method(:dismiss), 2000, false);
        _timer = t;
    }

    function onHide() as Void {
        // Covered or popped: don't let the timer pop someone else's view.
        var t = _timer;
        if (t != null) {
            t.stop();
            _timer = null;
        }
    }

    function dismiss() as Void {
        _timer = null;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, _message,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class StatusDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
