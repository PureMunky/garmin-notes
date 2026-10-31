# garmin-notes — Notes to Phone

A Garmin Connect IQ watch app: open it on your watch, enter a short note, and it shows up on your phone as a push notification (or goes to any webhook you choose).

> **Important limitation:** Connect IQ gives watch apps **no microphone or speech-to-text API**, so this app can't record your voice. You enter text on the watch instead (see below). If your watch has a mic and you want voice, use the watch's built-in voice-assistant / voice-notes feature through your phone.

## How it works

```
Watch app ──BLE──► Garmin Connect app (phone) ──HTTPS──► ntfy.sh / your webhook ──► phone notification
```

- **Ways to enter a note**
  - **Type note**: on-watch keyboard (`WatchUi.TextPicker`), on devices that have one.
  - **Quick note**: one tap on a preset phrase (set the list in the Garmin Connect app).
  - **Spell note**: pick letters one at a time with the buttons; works on button-only watches. Backing out saves a draft.
- **Saved outbox**: notes go into `Application.Storage` first and are removed only after the server confirms delivery. If the phone is out of range, they wait and are retried the next time you open the app (or tap *Send pending*).
- **Feedback**: a short vibration plus a toast or status screen ("Sent!", "No phone - saved", …).

## Phone setup (ntfy, the default)

1. Install the **ntfy** app (Android / iOS) and subscribe to a topic with a long random name, e.g. `phil-watch-7f3k9q2x`. ntfy.sh topics are public, so anyone who knows the name can read them.
2. In the **Garmin Connect** app: Device → Connect IQ Apps → Notes to Phone → Settings → enter the same **ntfy topic**.
3. Optional: a self-hosted ntfy server URL and a bearer token (for ntfy access tokens).

### Custom webhook instead

Set *Delivery method* to **Custom webhook** and enter an `https://` URL (Zapier, Make, n8n, IFTTT, your own server…). The app POSTs:

```json
{ "text": "Buy groceries", "timestamp": 1793450000, "local_time": "2026-10-31 08:15", "source": "garmin-watch" }
```

with `Authorization: Bearer <token>` if a token is set. From there you can send it on to Todoist, Notes, email, and so on.

## Build & install

1. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) (SDK 7.x or newer) and the **Monkey C** VS Code extension.
2. `Monkey C: Generate a Developer Key` (once).
3. Edit the device list: `Monkey C: Edit Products` (or `manifest.xml`). The device IDs listed there are a starting set; check that yours is included.
4. Run in the simulator: `Monkey C: Run App`. Web requests work in the simulator (they use your computer's network).
5. Sideload: `Monkey C: Build for Device` → copy the `.prg` to the watch's `GARMIN/APPS/` folder over USB.

Command line equivalent:

```sh
monkeyc -f monkey.jungle -d fr265 -y developer_key.der -o bin/GarminNotes.prg
monkeydo bin/GarminNotes.prg fr265
```

### Faster launch

Most watches let you put an app in the **Controls menu** or on a **hot key** (hold a button). Settings → Controls / Hot Keys → pick *Notes to Phone*. The app opens straight into the note menu.

## Layout

| File | Purpose |
|---|---|
| `source/GarminNotesApp.mc` | App entry point, `submit()` |
| `source/MainMenu.mc` | Main menu, keyboard delegate, presets menu |
| `source/SpellPicker.mc` | Letter-by-letter picker for button-only watches |
| `source/NoteQueue.mc` | Saved outbox and draft |
| `source/NoteSender.mc` | ntfy / webhook delivery, retry, error mapping |
| `source/StatusView.mc` | Toast / fallback status screen |
| `source/Text.mc` | String helpers (trim/split/etc.) |
| `resources/settings/` | Settings shown in the Garmin Connect app |

## Status

Not yet compiled: the code was written without the Connect IQ SDK available. Build it in the simulator first and expect a few type-checker fixes.
