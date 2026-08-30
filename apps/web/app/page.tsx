import { RewriteDemo } from "@/components/RewriteDemo";
import { APPS, DOWNLOAD, FAQ, GITHUB, MODES, NAME } from "@/lib/site";

export default function Home() {
  return (
    <>
      <div className="field" aria-hidden="true" />

      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:border focus:border-line focus:bg-surface focus:px-4 focus:py-2"
      >
        Skip to content
      </a>

      <Header />

      <main id="main">
        <Hero />
        <div className="mx-auto max-w-4xl px-6">
          <Modes />
          <Everywhere />
          <Privacy />
          <Install />
          <Questions />
        </div>
      </main>

      <Footer />
    </>
  );
}

/* ---------------------------------------------------------------- header */

function Header() {
  return (
    <header className="mx-auto flex max-w-4xl items-center justify-between px-6 py-5">
      <span className="flex items-center gap-2.5">
        <Mark />
        <span className="font-mono text-sm tracking-tight">{NAME}</span>
      </span>

      <nav className="flex items-center gap-1 text-sm">
        <a href="#install" className="rounded-md px-3 py-1.5 text-muted transition-colors hover:text-ink">
          Install
        </a>
        <a href="#faq" className="hidden rounded-md px-3 py-1.5 text-muted transition-colors hover:text-ink sm:block">
          FAQ
        </a>
        <a
          href={GITHUB}
          className="rounded-md border border-line px-3 py-1.5 transition-colors hover:border-sel"
        >
          GitHub
        </a>
      </nav>
    </header>
  );
}

function Mark({ size = 20 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M4.6 4.2h5.6M4.6 15.4h5.6M7.4 4.2v11.2"
        stroke="currentColor"
        strokeWidth="1.9"
        strokeLinecap="round"
        fill="none"
      />
      <path
        d="M16.4 2.6c.9 3.1 1.6 3.8 4.7 4.7-3.1.9-3.8 1.6-4.7 4.7-.9-3.1-1.6-3.8-4.7-4.7 3.1-.9 3.8-1.6 4.7-4.7Z"
        fill="var(--sel)"
      />
      <path
        d="M18.6 14.2c.5 1.7.9 2.1 2.6 2.6-1.7.5-2.1.9-2.6 2.6-.5-1.7-.9-2.1-2.6-2.6 1.7-.5 2.1-.9 2.6-2.6Z"
        fill="var(--sel)"
      />
    </svg>
  );
}

/* ------------------------------------------------------------------ hero */

function Hero() {
  return (
    <section className="mx-auto max-w-4xl px-6 pb-24 pt-12 sm:pt-20">
      <p className="eyebrow">Menu-bar app · macOS 13+</p>

      <h1 className="display mt-5 text-[2.75rem] sm:text-[4.25rem]">
        Fix your writing
        <br />
        where you wrote it.
      </h1>

      <p className="mt-7 max-w-2xl text-lg leading-relaxed text-muted sm:text-xl">
        Select text in any Mac app, press <Chord>⌘⇧R</Chord>, and it is replaced with a cleaner
        version. No copy-paste, no chat window, no switching apps.
      </p>

      <div className="mt-8 flex flex-wrap items-center gap-x-4 gap-y-3">
        <a
          href="#install"
          className="rounded-lg bg-ink px-5 py-3 text-sm font-medium text-bg transition-opacity hover:opacity-90"
        >
          Download for macOS
        </a>
        <a
          href={GITHUB}
          className="rounded-lg border border-line px-5 py-3 text-sm font-medium transition-colors hover:border-sel"
        >
          Read the source
        </a>
        <span className="font-mono text-xs text-muted">Free · MIT · bring your own API key</span>
      </div>

      <div className="mt-14">
        <RewriteDemo />
      </div>

      {/* The app's entire visible footprint, at roughly actual size. */}
      <div className="mt-8 flex flex-wrap items-center gap-4">
        <span className="menubar font-mono text-xs text-muted">
          <Mark size={14} />
          <span>✨ Rewrite Selected Text</span>
          <span className="opacity-50">⌘⇧R</span>
        </span>
        <p className="text-sm text-muted">
          Lives in the menu bar. No Dock icon, no window to keep open.
        </p>
      </div>
    </section>
  );
}

/* ----------------------------------------------------------------- modes */

function Modes() {
  return (
    <Section eyebrow="Four shortcuts" title="One keystroke, four ways to rewrite">
      <div className="grid gap-4 sm:grid-cols-2">
        {MODES.map((mode) => (
          <div key={mode.name} className="card">
            <div className="flex items-center justify-between gap-4">
              <h3 className="font-medium">{mode.name}</h3>
              <span className="flex shrink-0 items-center gap-1">
                {mode.keys.map((key) => (
                  <kbd
                    key={key}
                    className="grid h-6 min-w-6 place-items-center rounded border border-line px-1 font-mono text-[0.7rem] text-muted"
                  >
                    {key}
                  </kbd>
                ))}
              </span>
            </div>
            <p className="mt-2.5 text-sm leading-relaxed text-muted">{mode.detail}</p>
          </div>
        ))}
      </div>
      <p className="mt-6 text-sm text-muted">
        Every shortcut is configurable, and non-English text is translated into English.
      </p>
    </Section>
  );
}

/* ------------------------------------------------------------ everywhere */

function Everywhere() {
  return (
    <Section eyebrow="Anywhere you type" title="Works in the apps you already use">
      <div className="grid gap-8 sm:grid-cols-[1fr_1.1fr] sm:items-start">
        <p className="leading-relaxed text-muted">
          It reads your selection through the macOS Accessibility API, so it is not built for any
          one app. If you can select the text, you can rewrite it.
        </p>
        <ul className="flex flex-wrap gap-2">
          {APPS.map((app) => (
            <li
              key={app}
              className="rounded-md border border-line bg-surface px-2.5 py-1.5 font-mono text-xs text-muted"
            >
              {app}
            </li>
          ))}
          <li className="px-2.5 py-1.5 font-mono text-xs text-muted">and the rest</li>
        </ul>
      </div>
    </Section>
  );
}

/* --------------------------------------------------------------- privacy */

function Privacy() {
  const points = [
    ["Only when you ask", "Text is sent when you press a shortcut. Never in the background."],
    ["Never stored", "Not logged, not written to disk. Every request sets store to false, so OpenAI does not retain it."],
    ["Your key, your account", "The API key lives in your macOS Keychain. You pay OpenAI directly."],
    ["Your clipboard survives", "It is snapshotted and restored every time — images, formatting and all."],
  ];

  return (
    <Section eyebrow="Privacy" title="Your text goes to OpenAI and nowhere else">
      <div
        className="rounded-xl border border-line p-6 sm:p-8"
        style={{ background: "var(--surface)", boxShadow: "var(--shadow)" }}
      >
        <dl className="grid gap-x-10 gap-y-7 sm:grid-cols-2">
          {points.map(([term, detail]) => (
            <div key={term} className="border-l-2 pl-4" style={{ borderColor: "var(--sel)" }}>
              <dt className="font-medium">{term}</dt>
              <dd className="mt-1.5 text-sm leading-relaxed text-muted">{detail}</dd>
            </div>
          ))}
        </dl>
      </div>
    </Section>
  );
}

/* --------------------------------------------------------------- install */

function Install() {
  const steps = [
    [
      "Open it the first time",
      <>
        This build is not notarized yet, so macOS will say it cannot check the app. Right-click it
        and choose <em>Open</em>, or go to System Settings → Privacy &amp; Security →{" "}
        <em>Open Anyway</em>. Once only.
      </>,
    ],
    [
      "Allow Accessibility",
      <>
        macOS asks on first launch. This is how the app reads your selection and puts the rewritten
        text back — the only permission it needs. Relaunch after granting it.
      </>,
    ],
    [
      "Add your OpenAI key",
      <>
        Menu bar → Settings → paste your key → Save. It goes straight into the Keychain. Then select
        text anywhere and press <Chord>⌘⇧R</Chord>.
      </>,
    ],
  ] as const;

  return (
    <Section eyebrow="Install" title="Set it up in two minutes" id="install">
      <div className="flex flex-wrap items-center gap-x-5 gap-y-3">
        <a
          href={DOWNLOAD}
          className="inline-flex items-center gap-2 rounded-lg bg-ink px-5 py-3 text-sm font-medium text-bg transition-opacity hover:opacity-90"
        >
          Download AIRewriteAnywhere
          <span aria-hidden="true">↓</span>
        </a>
        <span className="font-mono text-xs text-muted">Universal · macOS 13 Ventura or later</span>
      </div>

      {/* Numbered because this genuinely is a sequence — each step depends on the one before. */}
      <ol className="mt-10 grid gap-4 sm:grid-cols-3">
        {steps.map(([title, body], index) => (
          <li key={String(title)} className="card">
            <span className="font-mono text-sm text-sel">{String(index + 1).padStart(2, "0")}</span>
            <h3 className="mt-3 font-medium">{title}</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted">{body}</p>
          </li>
        ))}
      </ol>

      <p className="mt-8 text-sm text-muted">
        Prefer to build it yourself?{" "}
        <a href={GITHUB} className="text-ink underline underline-offset-4">
          Clone the repo
        </a>{" "}
        and run <code className="font-mono text-xs">make install</code>.
      </p>
    </Section>
  );
}

/* ------------------------------------------------------------- questions */

function Questions() {
  return (
    <Section eyebrow="FAQ" title="Questions people ask first" id="faq">
      <div className="rule">
        {FAQ.map(({ q, a }) => (
          <details key={q} className="rule group border-t-0 py-4 first:pt-5">
            <summary className="flex cursor-pointer list-none items-start justify-between gap-6 font-medium marker:content-none">
              {q}
              <span
                className="mt-0.5 shrink-0 text-muted transition-transform duration-200 group-open:rotate-45"
                aria-hidden="true"
              >
                +
              </span>
            </summary>
            <p className="mt-3 max-w-2xl text-sm leading-relaxed text-muted">{a}</p>
          </details>
        ))}
      </div>
    </Section>
  );
}

/* ---------------------------------------------------------------- footer */

function Footer() {
  return (
    <footer className="mt-10 border-t border-line">
      <div className="mx-auto flex max-w-4xl flex-wrap items-center justify-between gap-4 px-6 py-8 font-mono text-xs text-muted">
        <span className="flex items-center gap-2">
          <Mark size={14} />
          {NAME} — MIT licensed
        </span>
        <span className="flex gap-5">
          <a href={GITHUB} className="hover:text-ink">
            GitHub
          </a>
          <a href={`${GITHUB}/issues`} className="hover:text-ink">
            Report an issue
          </a>
          <a href={`${GITHUB}/releases`} className="hover:text-ink">
            Releases
          </a>
        </span>
      </div>
    </footer>
  );
}

/* ---------------------------------------------------------------- shared */

function Section({
  eyebrow,
  title,
  id,
  children,
}: {
  eyebrow: string;
  title: string;
  id?: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="rule scroll-mt-8 py-20">
      <p className="eyebrow">{eyebrow}</p>
      <h2 className="display mt-3 text-[1.9rem] sm:text-[2.4rem]">{title}</h2>
      <div className="mt-9">{children}</div>
    </section>
  );
}

function Chord({ children }: { children: string }) {
  return (
    <kbd className="rounded border border-line bg-surface px-1.5 py-0.5 font-mono text-[0.8em] text-ink">
      {children}
    </kbd>
  );
}
