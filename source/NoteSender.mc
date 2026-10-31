import Toybox.Application;
import Toybox.Attention;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

//! Sends queued notes one at a time via Communications.makeWebRequest, which
//! is relayed over Bluetooth by the Garmin Connect app on the phone.
class NoteSender {
    enum Mode {
        MODE_NTFY = 0,
        MODE_WEBHOOK = 1
    }

    private var _busy as Boolean = false;
    private var _sentCount as Number = 0;
    private var _listener as Method? = null;

    function initialize() {
    }

    //! listener: method(ok as Boolean, message as String) as Void
    function setListener(listener as Method?) as Void {
        _listener = listener;
    }

    function flush() as Void {
        if (_busy) {
            return;
        }
        var note = NoteQueue.peek();
        if (note == null) {
            return;
        }
        if (!System.getDeviceSettings().phoneConnected) {
            report(false, "No phone - saved");
            return;
        }
        var req = buildRequest(note);
        if (req == null) {
            report(false, "Configure in Connect app");
            return;
        }
        _busy = true;
        Communications.makeWebRequest(
            req[0] as String,
            req[1] as Dictionary,
            req[2] as Dictionary,
            method(:onResponse)
        );
    }

    function onResponse(code as Number, data as Dictionary or String or Null) as Void {
        _busy = false;
        // -400 = server answered but the body could not be parsed; the note
        // was still delivered, so don't resend it and create duplicates.
        if ((code >= 200 && code < 300) || code == -400) {
            NoteQueue.removeFirst();
            _sentCount += 1;
            if (NoteQueue.size() > 0) {
                flush();
                return;
            }
            var n = _sentCount;
            _sentCount = 0;
            report(true, n == 1 ? "Sent!" : "Sent " + n + " notes");
        } else {
            _sentCount = 0;
            report(false, errorText(code));
        }
    }

    //! Returns [url, params, options] or null if not configured.
    private function buildRequest(note as Dictionary) as Array? {
        var text = note["text"] as String;
        var ts = note["ts"] as Number;
        var mode = Application.Properties.getValue("deliveryMode") as Number;
        var headers = { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON } as Dictionary;

        var token = Application.Properties.getValue("authToken") as String?;
        if (token != null && token.length() > 0) {
            headers["Authorization"] = "Bearer " + token;
        }

        if (mode == MODE_WEBHOOK) {
            var url = Application.Properties.getValue("webhookUrl") as String?;
            if (url == null || url.length() == 0) {
                return null;
            }
            return [url, {
                "text" => text,
                "timestamp" => ts,
                "local_time" => formatTime(ts),
                "source" => "garmin-watch"
            }, {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => headers,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
            }];
        }

        // ntfy: JSON publish to the server root. https://docs.ntfy.sh/publish/#publish-as-json
        var topic = Application.Properties.getValue("ntfyTopic") as String?;
        if (topic == null || topic.length() == 0) {
            return null;
        }
        var server = Application.Properties.getValue("ntfyServer") as String?;
        if (server == null || server.length() == 0) {
            server = "https://ntfy.sh";
        }
        return [Text.stripTrailingSlash(server), {
            "topic" => topic,
            "title" => "Watch note " + formatTime(ts),
            "message" => text,
            "tags" => ["watch"]
        }, {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        }];
    }

    private function formatTime(ts as Number) as String {
        var i = Gregorian.info(new Time.Moment(ts), Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$ $4$:$5$", [
            i.year,
            (i.month as Number).format("%02d"),
            i.day.format("%02d"),
            i.hour.format("%02d"),
            i.min.format("%02d")
        ]);
    }

    private function errorText(code as Number) as String {
        switch (code) {
            case -104: return "No phone - saved";
            case -2:
            case -300: return "Timed out - saved";
            case 401:
            case 403: return "Auth failed";
            case 404: return "URL not found";
            case 429: return "Rate limited";
            default: return "Error " + code + " - saved";
        }
    }

    private function report(ok as Boolean, message as String) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(ok ? 50 : 100, ok ? 150 : 500)]);
        }
        var l = _listener;
        if (l != null) {
            l.invoke(ok, message);
        }
    }
}
