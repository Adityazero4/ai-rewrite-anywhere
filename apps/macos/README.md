# PencilMark

Pencil Mark is a copy-editor that lives in your menu bar. It marks up whatever text you have
selected — in any macOS app — with one keystroke. Select text, press `⌘⇧R`, and the selection is replaced in place by an improved
version. No browser tab, no copy/paste, no per-app integration.

Works in Slack, Chrome, Safari, Gmail, Notion, VS Code, GitHub, Linear, Jira, Notes, TextEdit,
Mail, and any other app that exposes selectable text.

---

## Shortcuts

| Shortcut | Action | What it does |
|---|---|---|
| `⌘⇧R` | Rewrite | Grammatically correct, clear, natural, professional — meaning preserved |
| `⌘⇧G` | Fix Grammar | Grammar, spelling, punctuation, awkward phrasing only — wording preserved |
| `⌘⇧C` | Make Concise | Shorter and clearer, same meaning and tone |
| `⌘⇧P` | Make Professional | Polished and professional, same meaning |

Each is also in the menu-bar menu under the ✨ icon.

**All four are configurable.** Settings → Keyboard Shortcuts → click a shortcut and press the new
combination. Escape cancels, Delete restores the default, and there is a **Reset All**. Changes
apply immediately — no restart. A combination needs ⌘, ⌃ or ⌥ (shift alone would swallow normal
typing), and two actions can't share one — the recorder names the conflict instead.

## Prompts

All four modes share one **style context** and differ only in the job they do, so tone stays
consistent across them. The context is tuned for workplace and technical writing — Slack messages,
bug reports, pull request summaries, product feedback, interview notes, short social posts — and
asks for clear, concise, professional but *conversational* English that never reads as more formal
than the original.

It also pins down four things that matter for this kind of text:

- Non-English input is translated into English, so `kya kr rha hai bro` → `⌘⇧R` returns English.
- Code, identifiers, file paths, URLs, error messages, @mentions and ticket keys are left exactly
  as written.
- Line breaks, bullets, numbered lists and code blocks are preserved.
- No greetings, sign-offs or commentary get added, and the result is never wrapped in quotes.

Each mode then adds its own one-line task — see `styleContext` and `task` in
[`RewriteMode.swift`](Sources/PencilMarkCore/Models/RewriteMode.swift). Fix Grammar is deliberately a
proofread rather than a rewrite: it keeps the original wording wherever it is already correct.

## Knowing a rewrite is running

Two signals, both deliberately quiet:

- A small **"Rewriting…"** panel with a spinner near the bottom of the screen your pointer is on.
- The menu-bar icon changes from ✨ to a busy glyph.

Both appear only after ~400 ms, so fast rewrites never flash. The panel is a non-activating
`NSPanel` shown with `orderFrontRegardless()` and ignores mouse events — it must not take focus,
or it would count as "you switched apps" and cancel your own rewrite.

---

## Build and run

Requires macOS 13+ and the Xcode Command Line Tools (`xcode-select --install`). Full Xcode is
**not** required.

```bash
make test      # run the test suite
make app       # build build/PencilMark.app
make run       # build and launch
make install   # copy to /Applications (recommended — see permissions below)
```

`make app UNIVERSAL=1` produces a universal arm64 + x86_64 binary.

The app has no Dock icon and no main window; it lives in the menu bar as a ✨ icon.

---

## Permissions

**Accessibility** is required. It lets the app read the text you have selected in other apps and
put the rewritten text back. Without it the shortcuts do nothing.

On first launch the app asks for it and opens its Settings window. To grant it manually:

> System Settings → Privacy & Security → Accessibility → enable **PencilMark**

The Settings window has an **Open System Settings** button that jumps straight there, and shows
live permission status.

No other permissions are needed — no screen recording, no input monitoring, no full disk access.

### Two things that trip people up

**Grant the permission to one copy, at a stable path.** macOS keys the grant to the app's path
*and* its signature, so a copy in `build/` and a copy in `/Applications` are two different apps to
it — and `make app` deletes and recreates `build/`. `make run` therefore installs to
`/Applications` first and always launches that copy. Grant permission to
`/Applications/PencilMark.app` and nothing else.

**After enabling the toggle, the app must be restarted.** macOS answers `AXIsProcessTrusted()`
from a per-process cache, so an app that was already running when you flipped the switch keeps
seeing "denied" forever. The Settings window says so and offers a **Quit & Reopen** button.

**Code signing decides whether the grant survives a rebuild.** macOS ties the Accessibility grant
to the app's *designated requirement*. With an ad-hoc signature that requirement is the binary's
hash, so every rebuild silently invalidates the permission while the toggle still shows enabled.

`make app` therefore signs with the first real code-signing identity in your keychain (any Apple
Development certificate works) and falls back to ad-hoc only if there is none:

```bash
security find-identity -v -p codesigning   # what will be used
make app SIGN_ID=<hash-or-name>            # pick a specific one
make app SIGN_ID=-                         # force ad-hoc
```

With a real identity the requirement is identity-based and stable:

```
designated => identifier "com.aditya.pencilmark" and anchor apple generic
              and certificate leaf[subject.CN] = "Apple Development: …"
```

No hash, so rebuilds keep working. **Switching between signing identities does invalidate the
grant**, and the System Settings toggle keeps showing as enabled while recording the old
signature — which looks exactly like a bug. Clear the stale entry and start over:

```bash
tccutil reset Accessibility com.aditya.pencilmark
make run   # relaunches; grant when prompted
```

On first launch from a download, Gatekeeper may need a right-click → **Open**.

---

## Configuring the OpenAI API key

Open **Settings** from the menu-bar icon, paste your key into the **OpenAI API Key** field, and
click **Save**. It is stored in the **macOS Keychain** — never in a file, never in `UserDefaults`,
never in the source.

For development you can instead export `OPENAI_API_KEY` before launching; a key saved in Settings
takes precedence, and Settings tells you which one is in use.

The **Model** field defaults to `gpt-4.1-mini` and accepts any model available on the OpenAI
Responses API.

---

## Privacy

- Selected text is sent to OpenAI **only** when you press one of the four shortcuts (or pick the
  matching menu item). Nothing is sent in the background.
- Selected text is **never logged and never written to disk**. It exists only as a local value for
  the duration of the request.
- Requests are sent with `"store": false`, asking OpenAI not to retain them.
- The URL session is ephemeral with caching disabled.
- Your clipboard is snapshotted and restored whenever it has to be used — including when the paste
  fails or the API errors out. Images, RTF and file URLs survive intact.
- The API key lives in the Keychain.

---

## How it works

```
⌘⇧R  →  HotKeyManager (Carbon)  →  RewriteCoordinator
                                       ├─ TextSelectionService.capture()
                                       │     1. AXSelectedText on the focused element
                                       │     2. fallback: snapshot clipboard → ⌘C → read → restore
                                       ├─ OpenAIClient.rewrite()      POST /v1/responses
                                       └─ TextReplacementService.replace()
                                             1. set AXSelectedText directly (clipboard untouched)
                                             2. fallback: snapshot → write → ⌘V → restore
```

Two capture strategies because no single one covers macOS. Native apps (Notes, TextEdit, Mail)
expose `AXSelectedText` — instant, and the clipboard is never touched. Chromium and Electron apps
(Chrome, Slack, VS Code, Notion, Linear, Jira) usually don't, so a synthetic `⌘C` is used with a
full snapshot/restore around it.

Global shortcuts use Carbon's `RegisterEventHotKey`: it needs no Accessibility permission of its
own, no event tap, and no third-party dependency.

### Layout

```
Sources/PencilMarkCore/          library — all logic, unit tested
  Models/       RewriteMode · AppSettings · RewriteError
  Services/     OpenAIClient · TextSelectionService · TextReplacementService
                HotKeyManager · Keychain · Pasteboard · Keyboard · RewriteCoordinator
Sources/PencilMark/      executable — SwiftUI shell
  App/          App · AppDelegate
  UI/           MenuBarView · SettingsView · SettingsWindowController
Tests/PencilMarkCoreTests/       the suite (see below)
```

Logic sits in a library target so the executable stays a thin shell and everything meaningful is
testable. `HTTPTransport`, `RewriteService`, `SelectionReading`, `SelectionWriting`,
`PasteboardType` and `SecretStore` are protocols so the system-level pieces can be faked.

---

## Error handling

Every failure produces one plain-English alert and changes nothing else:

| Situation | Behavior |
|---|---|
| No Accessibility permission | Alert with an **Open Settings…** button |
| No API key set | Alert with an **Open Settings…** button |
| Nothing selected / app exposes no selection | "Select some text and try again" |
| Selection is empty or whitespace | "The selected text is empty" |
| You switch apps mid-request | Nothing is pasted; text and clipboard untouched |
| API error (401, 429, 5xx) | The server's own message, with the status code |
| Network error or timeout (30 s) | "Network error: …" |
| Model returns nothing | "The model returned an empty response" |
| Paste keystroke can't be sent | Clipboard restored, failure reported |
| Second shortcut pressed mid-rewrite | Ignored, so the two can't race for the clipboard |

Successful rewrites are silent — no dialogs, no confirmation. If a request takes longer than
400 ms the menu-bar icon switches to a busy glyph; fast rewrites never flicker.

---

## Testing

```bash
make test     # 122 checks
```

Covers prompt generation and the rewrite-mode table, shortcut display/validation/persistence/
collision handling, request construction, Responses API parsing
(including reasoning items preceding the message, and multi-part content), empty-response
handling, API error mapping (401/429/500/empty body), network error mapping, settings persistence
and the Keychain round-trip, and clipboard restoration across success, API-failure and
paste-failure paths — plus the coordinator's busy guard and loading-indicator timing.

The suite is a plain executable rather than an `XCTest` bundle: `XCTest.framework` ships only with
full Xcode, and SwiftPM cannot load swift-testing bundles with just the Command Line Tools
installed. `Tests/PencilMarkCoreTests/TestRunner.swift` is a ~60-line assertion harness.

### Manual test checklist

The Accessibility and `CGEvent` paths can't be unit tested. After `make install` and granting
permission:

1. **TextEdit** — type a sentence, select it, `⌘⇧R`. Replaced in place. (Accessibility path.)
2. **Notes** — same. (Accessibility path.)
3. **Chrome** — select text in a `<textarea>` (e.g. a GitHub comment box), `⌘⇧G`. (Clipboard path.)
4. **Slack** — type in the message box, select, `⌘⇧C`.
5. **VS Code** — select a comment, `⌘⇧P`. Note `⌘⇧P` also opens the command palette; the global
   shortcut takes priority.
6. **Clipboard safety** — copy an image, then rewrite text somewhere. Paste afterwards: the image
   must still be there.
7. **No selection** — click into an empty document and press `⌘⇧R`. One clear alert.
8. **Bad key** — set a nonsense API key, rewrite. One clear alert; the selection is unchanged.
9. **Focus change** — press `⌘⇧R`, immediately switch apps. Nothing is pasted anywhere.
10. **No permission** — remove the app from the Accessibility list, press `⌘⇧R`. Alert with the
    Settings button.

---

## Known limitations

- **Chromium/Electron Accessibility gaps.** Chrome, Slack, VS Code and friends usually don't expose
  `AXSelectedText`, so the clipboard fallback is used — about 100 ms slower and it briefly borrows
  the clipboard (always restored).
- **Paste success can't be verified.** macOS gives no acknowledgement that a synthetic `⌘V` was
  consumed. The app can report that the keystroke was *sent*, not that it landed.
- **Shortcut collisions.** `⌘⇧P` is VS Code's command palette and `⌘⇧C` is Chrome DevTools' inspect.
  The global hotkey wins while the app runs, which shadows those — rebind them in Settings if you
  need the originals. A combination another *app* already owns system-wide can fail to register;
  the app says which on launch, and the menu-bar items still work.
- **Secure text fields** (password fields) reject synthetic events by design.
- **Signing identity changes** (ad-hoc ↔ certificate, or a different certificate) invalidate the
  Accessibility grant and need a one-time remove/re-add. Rebuilds with the same identity are fine.
- **Undo.** Replacement goes through the target app's own text system, so its `⌘Z` usually undoes
  it — but this isn't guaranteed everywhere.
- **No streaming.** The rewrite appears all at once when the request completes.
- **Read-only text** (a rendered web page, a PDF) can be captured but not replaced; the paste
  simply does nothing.

## Possible next steps

- Custom prompts and a user-defined mode.
- A target-language picker, instead of always translating to English.
- Strip surrounding quotes when a model wraps its answer in them.
- A rewrite history with one-click revert.
- Provider abstraction beyond OpenAI (Anthropic, local models) — `RewriteService` is already the
  seam for it.
- Launch at login.
