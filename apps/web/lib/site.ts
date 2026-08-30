export const GITHUB = "https://github.com/Adityazero4/ai-rewrite-anywhere";
export const DOWNLOAD = `${GITHUB}/releases/latest/download/AIRewriteAnywhere.zip`;

/** Every canonical URL comes from here, so pointing a custom domain at the site is one variable. */
export const SITE_URL =
  process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ??
  "https://airewriteanywhere.vercel.app";

export const NAME = "AIRewriteAnywhere";
export const TAGLINE =
  "Select text in any Mac app, press a shortcut, and it is replaced with a cleaner version.";

export const MODES = [
  {
    keys: ["⌘", "⇧", "R"],
    name: "Rewrite",
    detail: "Fixes grammar and awkward phrasing, improves clarity and flow. Says the same thing, better.",
  },
  {
    keys: ["⌘", "⇧", "G"],
    name: "Fix grammar",
    detail: "A proofread, not a rewrite. Keeps your wording wherever it is already correct.",
  },
  {
    keys: ["⌘", "⇧", "C"],
    name: "Make concise",
    detail: "Cuts redundancy and filler without cutting substance. Same meaning, same tone, fewer words.",
  },
  {
    keys: ["⌘", "⇧", "P"],
    name: "Make professional",
    detail: "Polished and credible for colleagues, while staying conversational. Never corporate.",
  },
] as const;

export const APPS = [
  "Slack", "Chrome", "Safari", "Gmail", "Notion", "VS Code", "Linear",
  "Jira", "GitHub", "Notes", "Mail", "TextEdit", "Cursor", "Obsidian",
] as const;

export const FAQ = [
  {
    q: "Does it work in every Mac app?",
    a: "Anywhere macOS lets you select and edit text. Native apps like Notes, TextEdit and Mail are read directly through the Accessibility API. Chromium and Electron apps — Chrome, Slack, VS Code, Notion, Linear, Jira — use a clipboard fallback that is about 100 ms slower. Your clipboard is snapshotted and restored either way, so nothing you copied is lost.",
  },
  {
    q: "Is it free?",
    a: "The app is free and open source under the MIT licence. You bring your own OpenAI API key and pay OpenAI directly for what you use, which for everyday rewriting is a few cents a month on the default model.",
  },
  {
    q: "Where does my text go?",
    a: "To OpenAI, and only when you press one of the four shortcuts. Nothing is sent in the background. Your text is never logged and never written to disk, and every request is sent with store set to false, which asks OpenAI not to retain it. Your API key lives in the macOS Keychain.",
  },
  {
    q: "Why does macOS say the app cannot be checked for malware?",
    a: "Because this build is not yet notarised by Apple, which needs a paid Apple Developer account. The app is open source, so you can read every line or build it yourself. To open it the first time, right-click the app and choose Open, or go to System Settings, then Privacy and Security, and click Open Anyway. You only do this once.",
  },
  {
    q: "Why does it need Accessibility permission?",
    a: "That is the macOS API for reading the text you have selected in another app and putting the rewritten text back. It is the only permission the app asks for. No screen recording, no input monitoring, no full disk access.",
  },
  {
    q: "Can I change the keyboard shortcuts?",
    a: "Yes. Open Settings from the menu bar icon, click any shortcut, and press the new combination. Changes apply immediately. A shortcut needs Command, Control or Option so it cannot swallow ordinary typing.",
  },
  {
    q: "Does it work with languages other than English?",
    a: "It translates into English. If you write in Hindi, Hinglish, Spanish or anything else, the rewrite comes back as English while keeping your meaning and tone.",
  },
  {
    q: "What are the system requirements?",
    a: "macOS 13 Ventura or later, on Apple Silicon or Intel.",
  },
] as const;
