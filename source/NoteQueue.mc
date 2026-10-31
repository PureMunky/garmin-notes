import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

//! Persistent outbox. Notes survive app exit / watch reboot until the phone
//! confirms delivery, so nothing is lost when you're out of Bluetooth range.
module NoteQueue {
    const STORAGE_KEY = "queue";
    const MAX_NOTES = 50;

    function getAll() as Array {
        var q = Application.Storage.getValue(STORAGE_KEY);
        if (q == null) {
            return [];
        }
        return q as Array;
    }

    function add(text as String) as Void {
        if (text.length() == 0) {
            return;
        }
        var q = getAll();
        q.add({ "text" => text, "ts" => Time.now().value() });
        if (q.size() > MAX_NOTES) {
            q = q.slice(q.size() - MAX_NOTES, null);
        }
        Application.Storage.setValue(STORAGE_KEY, q as Application.PropertyValueType);
    }

    function peek() as Dictionary? {
        var q = getAll();
        return q.size() > 0 ? q[0] as Dictionary : null;
    }

    function removeFirst() as Void {
        var q = getAll();
        if (q.size() > 0) {
            Application.Storage.setValue(STORAGE_KEY, q.slice(1, null) as Application.PropertyValueType);
        }
    }

    function size() as Number {
        return getAll().size();
    }

    function clear() as Void {
        Application.Storage.deleteValue(STORAGE_KEY);
    }

    // Unfinished spelled note, kept when you back out of the spell picker.
    const DRAFT_KEY = "draft";

    function getDraft() as String {
        var d = Application.Storage.getValue(DRAFT_KEY);
        return d == null ? "" : d as String;
    }

    function setDraft(text as String) as Void {
        if (text.length() == 0) {
            Application.Storage.deleteValue(DRAFT_KEY);
        } else {
            Application.Storage.setValue(DRAFT_KEY, text);
        }
    }
}
