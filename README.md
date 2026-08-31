<div align="center">

<img src="docs/banner.png" alt="Pencil Mark — a copy-editor for every app you type in" width="820">

<br>

[![Release](https://img.shields.io/github/v/release/Adityazero4/pencilmark?color=1f4fd8&label=download)](https://github.com/Adityazero4/pencilmark/releases/latest)
[![CI](https://github.com/Adityazero4/pencilmark/actions/workflows/ci.yml/badge.svg)](https://github.com/Adityazero4/pencilmark/actions/workflows/ci.yml)
[![Platform](https://img.shields.io/badge/macOS-13%2B-14141a)](https://github.com/Adityazero4/pencilmark/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-14141a)](LICENSE)

**[Download](https://github.com/Adityazero4/pencilmark/releases/latest/download/PencilMark.zip)** ·
**[Website](https://pencilmark.vercel.app)** ·
**[App docs](apps/macos/README.md)**

</div>

---

**Pencil Mark is a copy-editor that lives in your Mac's menu bar.**

Select any text, press `⌘⇧R`, and it is marked up and set clean where it already sits. No
copy-paste, no chat window, no switching apps.

It reads your selection through the macOS Accessibility API, so it is not built for any one app.
Slack, Chrome, Safari, Gmail, Notion, VS Code, Linear, Jira, Notes, Mail — if you can select the
text, Pencil Mark can mark it up.

*Named for what an editor leaves in the margin: a light mark, a better line.*

## Four kinds of mark

| Shortcut | Action | What it does |
|---|---|---|
| `⌘⇧R` | Rewrite | Fixes grammar and awkward phrasing, improves clarity and flow |
| `⌘⇧G` | Fix grammar | A proofread, not a rewrite — keeps your wording where it is already correct |
| `⌘⇧C` | Make concise | Cuts redundancy and filler, not substance |
| `⌘⇧P` | Make professional | Polished and credible, while staying conversational |

Every shortcut is **configurable** — open Settings, click one, press the new combination. Changes
apply immediately, and a combination must include ⌘, ⌃ or ⌥ so it cannot swallow ordinary typing.

Text that is not in English **comes back in English**. Type `kya kr rha hai bro`, press `⌘⇧R`, get
English.

## Install

Download the [latest release](https://github.com/Adityazero4/pencilmark/releases/latest), unzip,
and move the app to `/Applications`. Then:

1. **Open it once by right-clicking → Open.** Builds are not notarized yet, so macOS will say it
   cannot check the app. You only do this the first time. ([Why?](#why-the-gatekeeper-warning))
2. **Grant Accessibility permission** when asked, then relaunch. This is how Pencil Mark reads your
   selection and puts the marked-up text back — it is the only permission it needs. macOS caches
   the answer per process, so the relaunch matters.
3. **Add your OpenAI API key** in Settings from the menu-bar icon. It goes straight to the Keychain.

Or build it yourself — only the Xcode Command Line Tools are needed, not full Xcode:

```bash
git clone https://github.com/Adityazero4/pencilmark.git
cd pencilmark/apps/macos
make install     # builds, signs, and copies to /Applications
```

## Privacy

- Your text goes to OpenAI **only** when you press a shortcut. Never in the background.
- It is **never logged and never written to disk**, and every request sets `store: false` so
  OpenAI does not retain it.
- Your API key lives in the **macOS Keychain**, not in a config file.
- Your clipboard is snapshotted and restored every time it has to be borrowed — images and
  formatting included.

## Guardrails

The app edits text you are in the middle of writing, so the failure modes matter more than usual.

- **A chat reply never reaches your document.** Models sometimes answer instead of rewriting —
  especially when a selection is rude or reads like a question aimed at them. Pencil Mark detects
  that and refuses to paste it, so your selection survives and you get an alert instead.
- **Your selection is data, not instructions.** The prompt states this explicitly, so text that
  looks like a command is rewritten rather than obeyed.
- **8,000 characters per rewrite**, refused before any request is sent. An accidental ⌘A cannot
  ship a whole document to OpenAI or run up a bill.
- **One rewrite at a time.** A second shortcut press while one is in flight is ignored, so two
  requests cannot race for the clipboard.

## The website

Built around the same idea as the app: a proof sheet, marked up in red and blue pencil. Live at
**[pencilmark.vercel.app](https://pencilmark.vercel.app)**.

<div align="center">
<img src="docs/site-light.png" alt="The Pencil Mark website in light mode" width="49%">
<img src="docs/site-dark.png" alt="The Pencil Mark website in dark mode" width="49%">
</div>

## Repository layout

```
apps/macos/   Swift package — the app itself, plus 204 tests
apps/web/     Next.js website
tools/        make-icon.swift — regenerates the icon, favicons and ASCII mark
docs/         images used by this README
```

Two independent projects in one repo. They share no build tooling, so there is no workspace
manager to install.

```bash
cd apps/macos && make test     # 204 checks
cd apps/macos && make run      # build, install to /Applications, launch
cd apps/web   && npm install && npm run dev
```

The macOS suite is a plain executable rather than an XCTest bundle: `XCTest.framework` ships only
with full Xcode, and SwiftPM cannot load swift-testing bundles with just the Command Line Tools.

## Releasing

Tag a version; GitHub Actions runs the tests, builds a universal binary, packages it, and
publishes the release.

```bash
git tag v1.2.0 && git push origin v1.2.0
```

<a id="why-the-gatekeeper-warning"></a>

### Why the Gatekeeper warning

Notarizing a Mac app requires a Developer ID certificate, which requires a paid Apple Developer
account. Until then releases are ad-hoc signed, and macOS asks for confirmation on first launch.
The notarization step is already written into [`release.yml`](.github/workflows/release.yml) and
skips itself when the credentials are absent — adding `APPLE_ID`, `APPLE_TEAM_ID`,
`APPLE_APP_PASSWORD`, `APPLE_CERT_P12` and `APPLE_CERT_PASSWORD` as repository secrets switches it
on with no code change.

Pencil Mark is open source precisely so you do not have to take an unsigned binary on trust —
read it, or build it yourself in one command.

## Known limitations

- Chromium and Electron apps rarely expose `AXSelectedText`, so those use a clipboard fallback
  that is roughly 100 ms slower. Your clipboard is always restored.
- macOS gives no acknowledgement that a synthetic paste was consumed, so the app can report that
  the keystroke was *sent*, not that it landed.
- `⌘⇧P` and `⌘⇧C` shadow VS Code's command palette and Chrome DevTools' inspect while the app
  runs. Rebind them in Settings if you need the originals.
- Password fields reject synthetic events by design.
- No streaming — the marked-up text appears all at once.
- Changing the signing identity invalidates the Accessibility grant, and the System Settings
  toggle keeps showing as enabled while recording the old signature. Clear it with
  `tccutil reset Accessibility com.aditya.pencilmark` and grant it again.

<details>
<summary>The mark, in characters</summary>

A pencil and a brush crossed, generated from the same drawing routine as the app icon by
[`tools/make-icon.swift`](tools/make-icon.swift), so it can never drift from it. It also prints
when you run `make app`, and in the browser console on the website.

```








                       .-.    .-:
                    .-====-  -++++=:
                   ==========++++++++
                    =======++++++++=
                     -===+++++++++-
                      :=+++++++++:
                      :+++++++++=:
                     -+++++++++===-
                    =++++++++=======
                  *@#++++++=======+#@*
                 *%@@@@#++-  -=+#@@@@%*=
                 %%#%%@@@=    -@@@%%#%%%.
                 %%%%%#*.      :%#%%%%%%#
                .%%*-.          .+%%%%%%*
                 .                 =#*:
```

</details>

## License

MIT — see [LICENSE](LICENSE).
