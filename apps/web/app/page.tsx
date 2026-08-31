import { ColophonMark } from "@/components/ColophonMark";
import { ThemeToggle } from "@/components/ThemeToggle";
import { RewriteDemo } from "@/components/RewriteDemo";
import { APPS, DOWNLOAD, FAQ, GITHUB, MODES, NAME, NAME_NOTE } from "@/lib/site";

/*
  Rendered once at build time and served as static HTML — no server work per request, so the
  first byte is as fast as the CDN can manage. Declared rather than inferred: if a dynamic API
  ever creeps in, the build fails loudly instead of quietly turning the page into a function.
*/
export const dynamic = "force-static";

/*
  Layout: a proof sheet on a desk. One narrow column of prose with a ruled left margin, the way
  a manuscript is set for marking up — everything hangs off that rule, nothing is centred, and
  the margin carries the folios the way an editor's marks sit beside the text.
*/

export default function Home() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:border focus:border-rule focus:bg-paper focus:px-4 focus:py-2"
      >
        Skip to content
      </a>

      <div className="mx-auto max-w-[68rem] px-5 sm:px-8">
        <Masthead />
        <main id="main" className="sheet">
          <Hero />
          <Modes />
          <Everywhere />
          <Privacy />
          <Install />
          <Questions />
        </main>
        <Colophon />
      </div>
    </>
  );
}

/* -------------------------------------------------------------- masthead */

function Masthead() {
  return (
    <header className="flex items-baseline justify-between gap-6 py-6">
      <span className="flex items-baseline gap-3">
        <span className="font-serif text-xl">{NAME}</span>
        <span className="folio hidden sm:inline">Copy-editor for macOS</span>
      </span>
      <nav className="flex items-center gap-4 font-mono text-[0.7rem] uppercase tracking-[0.12em] sm:gap-6">
        <a href="#install" className="text-muted transition-colors hover:text-ink">
          Install
        </a>
        <a href="#faq" className="hidden text-muted transition-colors hover:text-ink sm:inline">
          Questions
        </a>
        <a href={GITHUB} className="text-muted transition-colors hover:text-ink">
          Source
        </a>
        <span aria-hidden="true" className="text-rule">|</span>
        <ThemeToggle />
      </nav>
    </header>
  );
}

/* ------------------------------------------------------------------ hero */

function Hero() {
  return (
    <section className="border-b border-rule">
      <div className="grid sm:grid-cols-[8rem_1fr]">
        <Margin>Fol. 1</Margin>

        <div className="px-6 py-12 sm:px-12 sm:py-16">
          {/*
            Hanging the red rule off the first line makes the headline read as a corrected line
            rather than a slogan — the page states its thesis in its own visual language.
          */}
          <h1 className="editorial max-w-[19ch] text-[3rem] sm:text-[4.5rem]">
            A copy-editor for every app you{" "}
            <span className="relative whitespace-nowrap">
              <span className="italic">type in</span>
              <svg
                className="absolute -bottom-1 left-0 w-full"
                height="7"
                viewBox="0 0 200 7"
                preserveAspectRatio="none"
                aria-hidden="true"
              >
                <path
                  d="M1 4.2C40 2 62 5.4 100 3.4c34-1.8 58 1.6 99-.4"
                  stroke="var(--blue)"
                  strokeWidth="2"
                  fill="none"
                  strokeLinecap="round"
                />
              </svg>
            </span>
            .
          </h1>

          <p className="mt-8 max-w-[54ch] text-[1.0625rem] leading-[1.7] text-muted">
            Select any text, press <Chord>⌘⇧R</Chord>, and {NAME} marks it up and sets it clean —
            in Slack, in a pull request, in an email you are already halfway through. No
            copy-paste, no chat window, no switching apps.
          </p>

          <div className="mt-9 flex flex-wrap items-center gap-x-6 gap-y-3">
            <a
              href="#install"
              className="border border-ink bg-ink px-6 py-3 font-mono text-[0.75rem] uppercase tracking-[0.12em] text-paper transition-colors hover:bg-transparent hover:text-ink"
            >
              Download
            </a>
            <a
              href={GITHUB}
              className="border-b border-ink pb-0.5 font-mono text-[0.75rem] uppercase tracking-[0.12em] transition-colors hover:border-blue hover:text-blue"
            >
              Read the source
            </a>
            <span className="font-mono text-[0.7rem] text-muted">Free · MIT · macOS 13+</span>
          </div>
        </div>
      </div>

      <div className="border-t border-rule px-6 py-10 sm:px-12 sm:py-12">
        <RewriteDemo />
      </div>
    </section>
  );
}

/* ----------------------------------------------------------------- modes */

function Modes() {
  return (
    <Spread folio="Fol. 2" eyebrow="Four marks" title="One keystroke, four kinds of mark">
      <dl className="divide-y divide-rule border-y border-rule">
        {MODES.map((mode) => (
          <div key={mode.name} className="grid gap-2 py-5 sm:grid-cols-[10rem_1fr] sm:gap-8">
            <dt className="flex items-baseline gap-3">
              <span className="font-serif text-lg">{mode.name}</span>
            </dt>
            <dd className="flex flex-col gap-2 sm:flex-row sm:items-baseline sm:justify-between sm:gap-8">
              <span className="max-w-[54ch] text-[0.95rem] leading-relaxed text-muted">
                {mode.detail}
              </span>
              <span className="flex shrink-0 items-center gap-1">
                {mode.keys.map((key) => (
                  <kbd
                    key={key}
                    className="grid h-6 min-w-6 place-items-center rounded-[3px] border border-rule px-1 font-mono text-[0.7rem] text-muted"
                  >
                    {key}
                  </kbd>
                ))}
              </span>
            </dd>
          </div>
        ))}
      </dl>
      <p className="mt-6 text-sm text-muted">
        Every shortcut is configurable, and text that is not in English comes back in English.
      </p>
    </Spread>
  );
}

/* ------------------------------------------------------------ everywhere */

function Everywhere() {
  return (
    <Spread folio="Fol. 3" eyebrow="Any manuscript" title="Works wherever you already type">
      <p className="max-w-[56ch] text-[1rem] leading-[1.75] text-muted">
        {NAME} reads your selection through the macOS Accessibility API, so it is not built for
        any one app. If you can select the text, it can mark it up.
      </p>
      {/* Set as a run-on list, the way a colophon lists its sources. */}
      <p className="mt-7 max-w-[60ch] font-mono text-[0.8rem] leading-[2.1] text-muted">
        {APPS.map((app) => (
          <span key={app}>
            <span className="text-ink">{app}</span>
            <span className="text-rule"> / </span>
          </span>
        ))}
        <span>and the rest</span>
      </p>
    </Spread>
  );
}

/* --------------------------------------------------------------- privacy */

function Privacy() {
  const points = [
    ["Only when you ask", "Text is sent when you press a shortcut. Never in the background."],
    ["Never kept", "Not logged, not written to disk. Every request sets store to false, so OpenAI does not retain it."],
    ["Your key, your account", "The key lives in your macOS Keychain. You pay OpenAI directly."],
    ["Your clipboard survives", "Snapshotted and restored every time — images, formatting and all."],
  ];

  return (
    <Spread folio="Fol. 4" eyebrow="Provenance" title="Your text goes to OpenAI and nowhere else">
      <dl className="grid gap-x-12 gap-y-8 sm:grid-cols-2">
        {points.map(([term, detail]) => (
          <div key={term}>
            <dt className="font-serif text-lg">{term}</dt>
            <dd className="mt-1.5 max-w-[42ch] text-[0.95rem] leading-relaxed text-muted">
              {detail}
            </dd>
          </div>
        ))}
      </dl>
    </Spread>
  );
}

/* --------------------------------------------------------------- install */

function Install() {
  const steps = [
    [
      "Open it once by right-clicking",
      <>
        Builds are not notarized yet, so macOS will say it cannot check the app. Right-click and
        choose <em>Open</em>, or System Settings → Privacy &amp; Security → <em>Open Anyway</em>.
      </>,
    ],
    [
      "Allow Accessibility, then relaunch",
      <>
        This is how the app reads your selection and puts the corrected text back. It is the only
        permission it asks for.
      </>,
    ],
    [
      "Add your OpenAI key",
      <>
        Menu bar → Settings → paste → Save. It goes straight into the Keychain. Then select text
        anywhere and press <Chord>⌘⇧R</Chord>.
      </>,
    ],
  ] as const;

  return (
    <Spread folio="Fol. 5" eyebrow="Setting up" title="Two minutes, start to finish" id="install">
      <div className="flex flex-wrap items-center gap-x-6 gap-y-3">
        <a
          href={DOWNLOAD}
          className="border border-ink bg-ink px-6 py-3 font-mono text-[0.75rem] uppercase tracking-[0.12em] text-paper transition-colors hover:bg-transparent hover:text-ink"
        >
          Download · macOS
        </a>
        <span className="font-mono text-[0.7rem] text-muted">Universal · Ventura or later</span>
      </div>

      {/* Numbered because each step genuinely depends on the one before it. */}
      <ol className="mt-10 divide-y divide-rule border-y border-rule">
        {steps.map(([title, body], i) => (
          <li key={String(title)} className="grid gap-2 py-5 sm:grid-cols-[3rem_1fr] sm:gap-6">
            <span className="font-mono text-sm text-blue">{String(i + 1).padStart(2, "0")}</span>
            <span>
              <h3 className="font-serif text-lg">{title}</h3>
              <p className="mt-1.5 max-w-[56ch] text-[0.95rem] leading-relaxed text-muted">{body}</p>
            </span>
          </li>
        ))}
      </ol>

      <p className="mt-7 text-sm text-muted">
        Or build it yourself —{" "}
        <a href={GITHUB} className="border-b border-ink pb-0.5 text-ink hover:border-blue hover:text-blue">
          clone the repo
        </a>{" "}
        and run <code className="font-mono text-[0.85em]">make install</code>. Command Line Tools
        are enough; you do not need Xcode.
      </p>
    </Spread>
  );
}

/* ------------------------------------------------------------- questions */

function Questions() {
  return (
    <Spread folio="Fol. 6" eyebrow="Queries" title="Questions people ask first" id="faq" last>
      {/*
        Native <details> rather than a JS accordion: it is keyboard accessible for free, works
        with JavaScript off, and its content is in the DOM for search engines either way.
      */}
      <div className="divide-y divide-rule border-y border-rule">
        {FAQ.map(({ q, a }) => (
          <details key={q} className="group py-4">
            <summary className="flex cursor-pointer list-none items-baseline gap-4 font-serif text-lg marker:content-none">
              <span className="text-blue transition-transform duration-200 group-open:rotate-90">
                ›
              </span>
              {q}
            </summary>
            <p className="ml-8 mt-3 max-w-[62ch] text-[0.95rem] leading-[1.7] text-muted">{a}</p>
          </details>
        ))}
      </div>
    </Spread>
  );
}

/* -------------------------------------------------------------- colophon */

function Colophon() {
  return (
    <footer className="flex flex-wrap items-end justify-between gap-6 py-10 font-mono text-[0.7rem] text-muted">
      <span className="flex items-end gap-5">
        {/* The printer's device, set in characters. */}
        <ColophonMark />
        <span className="flex max-w-[42ch] flex-col gap-1.5 pb-1">
          <span className="not-italic">{NAME_NOTE}</span>
          <span>{NAME} · set in Instrument Serif &amp; IBM Plex · MIT</span>
        </span>
      </span>
      <span className="flex gap-6">
        <a href={GITHUB} className="hover:text-ink">
          GitHub
        </a>
        <a href={`${GITHUB}/issues`} className="hover:text-ink">
          Issues
        </a>
        <a href={`${GITHUB}/releases`} className="hover:text-ink">
          Releases
        </a>
      </span>
    </footer>
  );
}

/* ---------------------------------------------------------------- shared */

/** The ruled left margin of the proof, carrying the folio mark. */
function Margin({ children }: { children: React.ReactNode }) {
  return (
    <div className="hidden border-r border-rule px-4 pt-14 sm:block">
      <span className="folio [writing-mode:vertical-rl]">{children}</span>
    </div>
  );
}

function Spread({
  folio,
  eyebrow,
  title,
  id,
  last,
  children,
}: {
  folio: string;
  eyebrow: string;
  title: string;
  id?: string;
  last?: boolean;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className={`scroll-mt-6 ${last ? "" : "border-b border-rule"}`}>
      <div className="grid sm:grid-cols-[8rem_1fr]">
        <Margin>{folio}</Margin>
        <div className="px-6 py-12 sm:px-12 sm:py-16">
          <p className="folio">{eyebrow}</p>
          <h2 className="editorial mt-3 max-w-[20ch] text-[2rem] sm:text-[2.75rem]">{title}</h2>
          <div className="mt-9">{children}</div>
        </div>
      </div>
    </section>
  );
}

function Chord({ children }: { children: string }) {
  return (
    <kbd className="whitespace-nowrap rounded-[3px] border border-rule px-1.5 py-0.5 font-mono text-[0.8em] text-ink">
      {children}
    </kbd>
  );
}
