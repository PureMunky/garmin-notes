import Toybox.Lang;

//! Small string helpers (Monkey C has no split/trim built in).
module Text {
    function trim(s as String) as String {
        var chars = s.toCharArray();
        var start = 0;
        var stop = chars.size();
        while (start < stop && chars[start] == ' ') {
            start += 1;
        }
        while (stop > start && chars[stop - 1] == ' ') {
            stop -= 1;
        }
        return s.substring(start, stop) as String;
    }

    function split(s as String, sep as String) as Array<String> {
        var out = [] as Array<String>;
        var rest = s;
        while (true) {
            var i = rest.find(sep);
            var part = trim(i == null ? rest : rest.substring(0, i) as String);
            if (part.length() > 0) {
                out.add(part);
            }
            if (i == null) {
                break;
            }
            rest = rest.substring(i + sep.length(), rest.length()) as String;
        }
        return out;
    }

    function capitalize(s as String) as String {
        if (s.length() == 0) {
            return s;
        }
        return s.substring(0, 1).toUpper() + s.substring(1, s.length());
    }

    function stripTrailingSlash(s as String) as String {
        while (s.length() > 0 && s.substring(s.length() - 1, s.length()).equals("/")) {
            s = s.substring(0, s.length() - 1) as String;
        }
        return s;
    }

    //! Last n characters, prefixed with an ellipsis if truncated.
    function tail(s as String, n as Number) as String {
        if (s.length() <= n) {
            return s;
        }
        return "..." + s.substring(s.length() - n, s.length());
    }
}
