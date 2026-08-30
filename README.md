<div align="center">

```
                       -
                      ++:
                     ++++:
 :-------:.        .++++++-
%@@@@@@@@@@:     :=+++++++++:
 :-=@@@#--.  .-=++++++++++++++=-.
   .@@@+   .-=++++++++++++++++===-.
   .@@@+       .:=+++++++++==-.
   .@@@+          .=++=+===:
   .@@@+            :=====
   .@@@+             :===
   .@@@+              -=
   .@@@+
   .@@@+                      -
   :@@@*                     =**:
#@@@@@@@@@@.              .=*****+:
-*********+                  =*+.
                              -
```

# AIRewriteAnywhere

**Select text in any Mac app, press ⌘⇧R, and it is replaced with a cleaner version.**

No copy-paste. No chat window. No switching apps.

[Download](https://github.com/Adityazero4/ai-rewrite-anywhere/releases/latest) ·
[Website](https://airewriteanywhere.vercel.app) ·
[App docs](apps/macos/README.md)

</div>

---

## What is it

A free, open-source menu-bar app for macOS. It reads whatever you have selected through the
Accessibility API, sends it to the OpenAI API with one of four instructions, and replaces the
selection in place — in Slack, Chrome, Gmail, Notion, VS Code, Linear, Jira, Notes, or anywhere
else macOS exposes editable text.

| Shortcut | Action |
|---|---|
| `⌘⇧R` | Rewrite — clearer, more natural, same meaning |
| `⌘⇧G` | Fix grammar — a proofread, not a rewrite |
| `⌘⇧C` | Make concise |
| `⌘⇧P` | Make professional |

All four are configurable, and non-English text is translated into English.

**Privacy:** your text is sent only when you press a shortcut, never logged, never written to
disk, and every request sets `store: false`. Your API key lives in the macOS Keychain.

## Repository layout

```
apps/macos/   Swift package — the app. See apps/macos/README.md
apps/web/     Next.js landing page
tools/        make-icon.swift — regenerates the app icon and web favicons
```

Two independent projects in one repo. They share no build tooling, so there is no workspace
manager to install.

## Working on it

```bash
# the macOS app
cd apps/macos
make test        # 178 checks
make run         # build, install to /Applications, launch

# the website
cd apps/web
npm install && npm run dev
```

Building the app needs only the Xcode Command Line Tools (`xcode-select --install`) — full Xcode
is not required.

## Releasing

Tag a version and GitHub Actions builds, packages and publishes the release:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

Builds are ad-hoc signed and **not yet notarised**, so macOS asks for confirmation on first
launch. Adding `APPLE_ID`, `APPLE_TEAM_ID` and `APPLE_APP_PASSWORD` as repository secrets turns
on the notarisation step that is already in the workflow.

## Licence

MIT — see [LICENSE](LICENSE).
