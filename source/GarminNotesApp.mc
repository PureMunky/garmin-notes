import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Entry point. Launching the app drops you straight into the note menu,
//! so "activate on watch -> enter note -> sent" is as few presses as possible.
class GarminNotesApp extends Application.AppBase {
    var sender as NoteSender;
    var menu as MainMenu?;

    function initialize() {
        AppBase.initialize();
        sender = new NoteSender();
    }

    function onStart(state as Dictionary?) as Void {
        sender.setListener(method(:onSendResult));
    }

    function onStop(state as Dictionary?) as Void {
        sender.setListener(null);
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var m = new MainMenu();
        menu = m;
        // Retry anything left over from a previous session (e.g. phone was away).
        if (NoteQueue.size() > 0) {
            sender.flush();
        }
        return [m, new MainMenuDelegate()];
    }

    //! Queue a note and try to deliver it immediately.
    function submit(text as String) as Void {
        NoteQueue.add(Text.capitalize(Text.trim(text)));
        refreshMenu();
        sender.flush();
    }

    function onSendResult(ok as Boolean, message as String) as Void {
        refreshMenu();
        StatusView.show(message);
    }

    function onSettingsChanged() as Void {
        refreshMenu();
        WatchUi.requestUpdate();
    }

    function refreshMenu() as Void {
        var m = menu;
        if (m != null) {
            m.refresh();
        }
    }
}

function getApp() as GarminNotesApp {
    return Application.getApp() as GarminNotesApp;
}
