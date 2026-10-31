import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Root view: the app opens straight into this menu.
class MainMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Notes" });
        if (WatchUi has :TextPicker) {
            addItem(new WatchUi.MenuItem("Type note", "Keyboard", :type, null));
        }
        addItem(new WatchUi.MenuItem("Quick note", "Presets", :quick, null));
        addItem(new WatchUi.MenuItem("Spell note", spellLabel(), :spell, null));
        addItem(new WatchUi.MenuItem("Send pending", pendingLabel(), :send, null));
        addItem(new WatchUi.MenuItem("Clear pending", null, :clear, null));
    }

    function refresh() as Void {
        setSub(:send, pendingLabel());
        setSub(:spell, spellLabel());
        WatchUi.requestUpdate();
    }

    private function setSub(id as Symbol, label as String) as Void {
        var idx = findItemById(id);
        if (idx >= 0) {
            var item = getItem(idx);
            if (item != null) {
                item.setSubLabel(label);
                updateItem(item, idx);
            }
        }
    }

    private function pendingLabel() as String {
        var n = NoteQueue.size();
        return n == 0 ? "Nothing waiting" : n + " waiting";
    }

    private function spellLabel() as String {
        var d = NoteQueue.getDraft();
        return d.length() == 0 ? "Letter by letter" : "Resume: " + Text.tail(d, 10);
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :type) {
            WatchUi.pushView(new WatchUi.TextPicker(""), new NoteTextDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :quick) {
            WatchUi.pushView(new QuickMenu(), new QuickMenuDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :spell) {
            var draft = NoteQueue.getDraft();
            WatchUi.pushView(new SpellPicker(draft, SpellChars.DEFAULT_INDEX),
                new SpellDelegate(draft), WatchUi.SLIDE_LEFT);
        } else if (id == :send) {
            if (NoteQueue.size() == 0) {
                StatusView.show("Nothing to send");
            } else {
                getApp().sender.flush();
            }
        } else if (id == :clear) {
            NoteQueue.clear();
            getApp().refreshMenu();
            StatusView.show("Cleared");
        }
    }
}

class NoteTextDelegate extends WatchUi.TextPickerDelegate {
    function initialize() {
        TextPickerDelegate.initialize();
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (text.length() > 0) {
            getApp().submit(text);
        }
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }
}

//! One-tap presets, configured in the Garmin Connect app settings.
class QuickMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Quick note" });
        var raw = Application.Properties.getValue("presets") as String?;
        var presets = Text.split(raw == null ? "" : raw, ",");
        if (presets.size() == 0) {
            addItem(new WatchUi.MenuItem("(no presets)", "Set in Connect app", :none, null));
        }
        for (var i = 0; i < presets.size(); i++) {
            addItem(new WatchUi.MenuItem(presets[i], null, presets[i], null));
        }
    }
}

class QuickMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof String) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            getApp().submit(id);
        }
    }
}
