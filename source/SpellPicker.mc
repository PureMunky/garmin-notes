import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Letter-by-letter entry for button-only watches without a keyboard.
//! Scroll up/down to pick a character, START adds it. "OK" sends, "DEL" deletes.
//! Backing out keeps the text as a draft you can resume from the main menu.
module SpellChars {
    const OK = "OK";
    const DEL = "DEL";
    const SPACE = "SPACE";
    const DEFAULT_INDEX = 3; // "a"

    function all() as Array<String> {
        var out = [OK, DEL, SPACE] as Array<String>;
        var chars = "abcdefghijklmnopqrstuvwxyz0123456789.,?!'-".toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            out.add(chars[i].toString());
        }
        return out;
    }
}

class CharFactory extends WatchUi.PickerFactory {
    private var _items as Array<String>;

    function initialize(items as Array<String>) {
        PickerFactory.initialize();
        _items = items;
    }

    function getSize() as Number {
        return _items.size();
    }

    function getValue(index as Number) as Object? {
        return _items[index];
    }

    function getDrawable(index as Number, selected as Boolean) as WatchUi.Drawable? {
        return new WatchUi.Text({
            :text => _items[index],
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}

class SpellPicker extends WatchUi.Picker {
    function initialize(text as String, defaultIndex as Number) {
        var title = new WatchUi.Text({
            :text => text.length() == 0 ? "Spell note" : Text.tail(text, 14),
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_TINY,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });
        Picker.initialize({
            :title => title,
            :pattern => [new CharFactory(SpellChars.all())],
            :defaults => [defaultIndex]
        });
    }
}

class SpellDelegate extends WatchUi.PickerDelegate {
    private var _text as String;

    function initialize(text as String) {
        PickerDelegate.initialize();
        _text = text;
    }

    function onAccept(values as Array) as Boolean {
        var ch = values[0] as String;
        if (ch.equals(SpellChars.OK)) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            NoteQueue.setDraft("");
            if (_text.length() > 0) {
                getApp().submit(_text);
            } else {
                getApp().refreshMenu();
            }
            return true;
        }
        if (ch.equals(SpellChars.DEL)) {
            if (_text.length() > 0) {
                _text = _text.substring(0, _text.length() - 1) as String;
            }
        } else if (ch.equals(SpellChars.SPACE)) {
            _text += " ";
        } else {
            _text += ch;
        }
        // Re-open on the same character so repeated letters / deletes are quick.
        var idx = SpellChars.all().indexOf(ch);
        WatchUi.switchToView(new SpellPicker(_text, idx), new SpellDelegate(_text), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onCancel() as Boolean {
        NoteQueue.setDraft(_text);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        getApp().refreshMenu();
        return true;
    }
}
