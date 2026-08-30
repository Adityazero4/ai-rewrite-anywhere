import { RewriteDemo } from "@/components/RewriteDemo";
import { APPS, DOWNLOAD, FAQ, GITHUB, MODES, NAME } from "@/lib/site";

export default function Home() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-surface focus:px-4 focus:py-2"
      >
        Skip to content
      </a>

      <Header />

      <main id="main" className="mx-auto max-w-3xl px-6 pb-32">
        <Hero />
        <Modes />
        <Everywhere />
        <Privacy />
        <Install />
        <Questions />
      </main>

      <Footer />
    </>
  );
}

/* ---------------------------------------------------------------- header */

function Header() {
  return (
    <header className="mx-auto flex max-w-3xl items-center justify-between px-6 py-6">
      <span className="flex items-center gap-2.5">
        {/* The mark, inline — same geometry as the app icon. */}
        <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true">
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
        <span className="font-mono text-sm tracking-tight">{NAME}</span>
      </span>

      <nav className="flex items-center gap-5 text-sm">
        <a href="#install" className="text-muted transition-colors hover:text-ink">
          Install
        </a>
        <a href={GITHUB} className="text-muted transition-colors hover:text-ink">
          GitHub
        </a>
      </nav>
    </header>
  );
}

/* ------------------------------------------------------------------ hero */

function Hero() {
  return (
    <section className="pb-20 pt-10 sm:pt-16">
      <h1 className="display text-[2.6rem] sm:text-[3.6rem]">
        Fix your writing
        <br />
        where you wrote it.
      </h1>

      <p className="mt-6 max-w-xl text-lg leading-relaxed text-muted">
        <strong className="font-medium text-ink">{NAME}</strong> is a free menu-bar app for macOS.
        Select text in any app, press <Chord>⌘⇧R</Chord>, and it is replaced with a cleaner
        version. No copy-paste, no chat window, no switching apps.
      </p>

      <div className="mt-9">
        <RewriteDemo />
      </div>

      <div className="mt-8 flex flex-wrap items-center gap-x-5 gap-y-3">
        <a
          href="#install"
          className="rounded-lg bg-ink px-5 py-2.5 text-sm font-medium text-bg transition-opacity hover:opacity-90"
        >
          Download for macOS
        </a>
        <a href={GITHUB} className="text-sm text-muted underline-offset-4 hover:text-ink hover:underline">
          Read the source
        </a>
        <span className="font-mono text-xs text-muted">Free · MIT · macOS 13+</span>
      </div>
    </section>
  );
}

/* ----------------------------------------------------------------- modes */

function Modes() {
  return (
    <Section eyebrow="Four shortcuts" title="One keystroke, four ways to rewrite">
      <ul className="rule">
        {MODES.map((mode) => (
          <li
            key={mode.name}
            className="rule flex flex-col gap-1.5 border-t-0 py-5 first:pt-6 sm:flex-row sm:items-baseline sm:gap-8"
          >
            <span className="flex shrink-0 items-center gap-1 sm:w-28">
              {mode.keys.map((key) => (
                <kbd
                  key={key}
                  className="grid h-6 min-w-6 place-items-center rounded border border-line px-1 font-mono text-[0.7rem] text-muted"
                >
                  {key}
                </kbd>
              ))}
            </span>
            <span className="min-w-0">
              <h3 className="font-medium">{mode.name}</h3>
              <p className="mt-1 text-sm leading-relaxed text-muted">{mode.detail}</p>
            </span>
          </li>
        ))}
      </ul>
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
      <p className="max-w-xl leading-relaxed text-muted">
        It reads the selection through the macOS Accessibility API, so it is not built for any one
        app. If you can select the text, you can rewrite it.
      </p>
      <ul className="mt-7 flex flex-wrap gap-2">
        {APPS.map((app) => (
          <li
            key={app}
            className="rounded-md border border-line px-2.5 py-1 font-mono text-xs text-muted"
          >
            {app}
          </li>
        ))}
        <li className="px-2.5 py-1 font-mono text-xs text-muted">and the rest</li>
      </ul>
    </Section>
  );
}

/* --------------------------------------------------------------- privacy */

function Privacy() {
  const points = [
    ["Only when you ask", "Text is sent when you press a shortcut. Never in the background."],
    ["Never stored", "Not logged, not written to disk. Requests set store to false so OpenAI does not retain them."],
    ["Your key, your account", "The API key lives in your macOS Keychain. You pay OpenAI directly."],
    ["Your clipboard survives", "It is snapshotted and restored every time, images and all."],
  ];

  return (
    <Section eyebrow="Privacy" title="Your text goes to OpenAI and nowhere else">
      <dl className="grid gap-x-10 gap-y-6 sm:grid-cols-2">
        {points.map(([term, detail]) => (
          <div key={term}>
            <dt className="font-medium">{term}</dt>
            <dd className="mt-1 text-sm leading-relaxed text-muted">{detail}</dd>
          </div>
        ))}
      </dl>
    </Section>
  );
}

/* --------------------------------------------------------------- install */

function Install() {
  return (
    <Section eyebrow="Install" title="Set it up in two minutes" id="install">
      <a
        href={DOWNLOAD}
        className="inline-flex items-center gap-2 rounded-lg bg-ink px-5 py-2.5 text-sm font-medium text-bg transition-opacity hover:opacity-90"
      >
        Download AIRewriteAnywhere
        <span aria-hidden="true">↓</span>
      </a>
      <p className="mt-3 font-mono text-xs text-muted">Universal · macOS 13 Ventura or later</p>

      {/* Numbered because this genuinely is a sequence — each step depends on the one before. */}
      <ol className="mt-9 space-y-6">
        {[
          [
            "Open it the first time",
            <>
              This build is not notarised yet, so macOS will say it cannot check the app.
              Right-click it and choose <em>Open</em>, or go to System Settings → Privacy &amp;
              Security → <em>Open Anyway</em>. Once only.
            </>,
          ],
          [
            "Allow Accessibility",
            <>
              macOS asks on first launch. This is how the app reads your selection and puts the
              rewritten text back — the only permission it needs. Relaunch after granting it.
            </>,
          ],
          [
            "Add your OpenAI key",
            <>
              Menu bar → Settings → paste your key → Save. It goes straight into the Keychain.
              Then select some text anywhere and press <Chord>⌘⇧R</Chord>.
            </>,
          ],
        ].map(([title, body], index) => (
          <li key={String(title)} className="flex gap-5">
            <span className="mt-0.5 font-mono text-sm text-sel">{index + 1}</span>
            <span className="min-w-0">
              <h3 className="font-medium">{title}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-muted">{body}</p>
            </span>
          </li>
        ))}
      </ol>

      <p className="mt-9 text-sm text-muted">
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
    <Section eyebrow="FAQ" title="Questions people ask first">
      <div className="rule">
        {FAQ.map(({ q, a }) => (
          <details key={q} className="rule group border-t-0 py-4 first:pt-5">
            <summary className="flex cursor-pointer list-none items-start justify-between gap-6 font-medium marker:content-none">
              {q}
              <span
                className="mt-1 shrink-0 text-muted transition-transform duration-200 group-open:rotate-45"
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
    <footer className="rule mx-auto max-w-3xl px-6 py-8">
      <div className="flex flex-wrap items-center justify-between gap-4 font-mono text-xs text-muted">
        <span>{NAME} — MIT licensed</span>
        <span className="flex gap-5">
          <a href={GITHUB} className="hover:text-ink">
            GitHub
          </a>
          <a href={`${GITHUB}/issues`} className="hover:text-ink">
            Report an issue
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
    <section id={id} className="rule scroll-mt-8 pb-20 pt-16">
      <p className="eyebrow">{eyebrow}</p>
      <h2 className="display mt-3 text-[1.75rem] sm:text-[2.1rem]">{title}</h2>
      <div className="mt-8">{children}</div>
    </section>
  );
}

function Chord({ children }: { children: string }) {
  return (
    <kbd className="rounded border border-line px-1.5 py-0.5 font-mono text-[0.8em] text-ink">
      {children}
    </kbd>
  );
}
