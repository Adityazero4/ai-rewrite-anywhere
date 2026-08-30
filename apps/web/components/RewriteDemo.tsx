"use client";

import { useEffect, useState } from "react";

/*
  The hero's thesis. This app has no interface worth screenshotting — the whole product is a
  keystroke that changes text where it already sits. So the demo puts the text back where it
  lives: inside a window, in a real app, mid-conversation.

  The typography carries the transformation. The draft is monospace — raw, typed, unfinished.
  The result is the proportional face — composed. The face change *is* the rewrite.
*/

const EXAMPLES = [
  {
    app: "Slack",
    context: "#eng-platform",
    before:
      "hey so the deploy is failing again i think its the env var thing we talked about, can u check when ur free? not urgent but blocking me",
    after:
      "Hey — the deploy is failing again. I think it's the env var issue we discussed. Could you take a look when you get a chance? Not urgent, but it's blocking me.",
  },
  {
    app: "Linear",
    context: "ENG-412 · Description",
    before:
      "the button dont work on mobile, when u click it nothing happens at all. tested on iphone 14 safari and also chrome android same thing",
    after:
      "The button does not respond on mobile — tapping it produces no visible action. Reproduced on iPhone 14 (Safari) and Android (Chrome).",
  },
  {
    app: "Gmail",
    context: "Re: Q3 roadmap",
    before:
      "thanks for sending this over. i had a look and mostly lgtm, just few things i wasnt sure about which we can maybe discuss tomorrow?",
    after:
      "Thanks for sending this over. I've read through it and it mostly looks good. There are a few points I'm unsure about — could we discuss them tomorrow?",
  },
] as const;

type Phase = "idle" | "selecting" | "pressed" | "working" | "done";

const TIMELINE: Record<Phase, { next: Phase; ms: number }> = {
  idle: { next: "selecting", ms: 900 },
  selecting: { next: "pressed", ms: 700 },
  pressed: { next: "working", ms: 300 },
  working: { next: "done", ms: 900 },
  done: { next: "idle", ms: 3600 },
};

const CAPTION: Record<Phase, string> = {
  idle: "A message you actually typed",
  selecting: "Select it",
  pressed: "Press the shortcut",
  working: "Rewriting",
  done: "Replaced, in place",
};

export function RewriteDemo() {
  const [index, setIndex] = useState(0);
  const [phase, setPhase] = useState<Phase>("idle");
  const [animate, setAnimate] = useState(false);

  useEffect(() => {
    const query = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (query.matches) {
      setPhase("done"); // the animation is the point; without motion, show the outcome
      return;
    }
    setAnimate(true);
  }, []);

  useEffect(() => {
    if (!animate) return;
    const { next, ms } = TIMELINE[phase];
    const timer = setTimeout(() => {
      setPhase(next);
      if (next === "idle") setIndex((i) => (i + 1) % EXAMPLES.length); // rotate through the apps
    }, ms);
    return () => clearTimeout(timer);
  }, [phase, animate]);

  const example = EXAMPLES[index];
  const highlighted = phase !== "idle";
  const rewritten = phase === "done";
  const keysLit = phase === "pressed" || phase === "working";

  const selectExample = (next: number) => {
    setIndex(next);
    setPhase("idle");
  };

  return (
    <figure className="m-0">
      <div className="window">
        {/* macOS window chrome — the text lives inside an app, not on a marketing page. */}
        <div className="window-bar">
          <span className="flex gap-[6px]" aria-hidden="true">
            <i className="light" style={{ background: "#ff5f57" }} />
            <i className="light" style={{ background: "#febc2e" }} />
            <i className="light" style={{ background: "#28c840" }} />
          </span>

          <div
            className="flex items-center gap-1"
            role="tablist"
            aria-label="Example applications"
          >
            {EXAMPLES.map((item, i) => (
              <button
                key={item.app}
                role="tab"
                aria-selected={i === index}
                onClick={() => selectExample(i)}
                className={`rounded-md px-2.5 py-1 font-mono text-[0.7rem] transition-colors ${
                  i === index ? "bg-[var(--chip)] text-ink" : "text-muted hover:text-ink"
                }`}
              >
                {item.app}
              </button>
            ))}
          </div>

          <span className="w-[52px]" aria-hidden="true" />
        </div>

        <div className="px-5 pb-5 pt-4 sm:px-7 sm:pb-6">
          <p className="eyebrow mb-3">{example.context}</p>

          {/* Both drafts share one grid cell so the window never jumps as they swap. */}
          {/*
            The two drafts share a cell, so they must never be visible at once — a simultaneous
            crossfade superimposes them into an unreadable smear. Whichever is arriving waits for
            the other to finish leaving.
          */}
          <div className="grid min-h-[4.75rem] text-[0.95rem] leading-relaxed sm:text-base">
            <p
              className={`col-start-1 row-start-1 font-mono transition-opacity ${
                rewritten ? "pointer-events-none opacity-0" : "opacity-100"
              }`}
              style={{ transitionDuration: "220ms", transitionDelay: rewritten ? "0ms" : "240ms" }}
            >
              <span
                className="box-decoration-clone bg-no-repeat transition-[background-size] duration-700 ease-out"
                style={{
                  backgroundImage: "linear-gradient(var(--sel-wash), var(--sel-wash))",
                  backgroundSize: highlighted ? "100% 100%" : "0% 100%",
                }}
              >
                {example.before}
              </span>
            </p>

            <p
              className={`col-start-1 row-start-1 transition-opacity ${
                rewritten ? "opacity-100" : "pointer-events-none opacity-0"
              }`}
              style={{ transitionDuration: "220ms", transitionDelay: rewritten ? "240ms" : "0ms" }}
            >
              {example.after}
            </p>
          </div>

          <div className="rule mt-5 flex items-center justify-between gap-4 pt-4">
            <span className="eyebrow" aria-live="polite">
              {CAPTION[phase]}
            </span>
            <Keys lit={keysLit} />
          </div>
        </div>
      </div>

      <figcaption className="sr-only">
        A {example.app} message reading &ldquo;{example.before}&rdquo; is selected, the Command
        Shift R shortcut is pressed, and it is replaced in place with &ldquo;{example.after}&rdquo;
      </figcaption>
    </figure>
  );
}

function Keys({ lit }: { lit: boolean }) {
  return (
    <span className="flex shrink-0 items-center gap-1" aria-hidden="true">
      {["⌘", "⇧", "R"].map((key) => (
        <kbd
          key={key}
          className="grid h-7 min-w-7 place-items-center rounded-md border px-1.5 font-mono text-xs transition-all duration-150"
          style={{
            borderColor: lit ? "var(--sel)" : "var(--line)",
            background: lit ? "var(--sel-wash)" : "transparent",
            color: lit ? "var(--sel)" : "var(--muted)",
            transform: lit ? "translateY(1px)" : "none",
            boxShadow: lit ? "0 0 0 4px var(--sel-glow)" : "none",
          }}
        >
          {key}
        </kbd>
      ))}
    </span>
  );
}
