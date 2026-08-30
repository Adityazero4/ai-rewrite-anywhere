"use client";

import { useEffect, useState } from "react";

/*
  The hero's thesis. This app has no interface worth screenshotting — the whole product is a
  keystroke that changes text where it already sits. So the hero shows exactly that, using the
  one artifact every user touches first: the macOS selection highlight.

  The typography carries the idea. The draft is monospace — raw, typed, unfinished. The result is
  the proportional face — composed. The face change *is* the transformation.
*/

const BEFORE =
  "hey so the deploy is failing again i think its the env var thing we talked about, can u check when ur free? not urgent but blocking me";

const AFTER =
  "Hey — the deploy is failing again. I think it's the env var issue we discussed. Could you take a look when you get a chance? Not urgent, but it's blocking me.";

type Phase = "idle" | "selecting" | "pressed" | "working" | "done";

const TIMELINE: Record<Phase, { next: Phase; ms: number }> = {
  idle: { next: "selecting", ms: 1000 },
  selecting: { next: "pressed", ms: 750 },
  pressed: { next: "working", ms: 280 },
  working: { next: "done", ms: 950 },
  done: { next: "idle", ms: 3400 },
};

const CAPTION: Record<Phase, string> = {
  idle: "A message you actually typed",
  selecting: "Select it",
  pressed: "Press the shortcut",
  working: "Rewriting",
  done: "Replaced, in place",
};

export function RewriteDemo() {
  const [phase, setPhase] = useState<Phase>("idle");
  const [animate, setAnimate] = useState(false);

  useEffect(() => {
    // Without motion the demo is meaningless as an animation, so show the finished state instead.
    const query = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (query.matches) {
      setPhase("done");
      return;
    }
    setAnimate(true);
  }, []);

  useEffect(() => {
    if (!animate) return;
    const { next, ms } = TIMELINE[phase];
    const timer = setTimeout(() => setPhase(next), ms);
    return () => clearTimeout(timer);
  }, [phase, animate]);

  const highlighted = phase !== "idle";
  const rewritten = phase === "done";
  const keysLit = phase === "pressed" || phase === "working";

  return (
    <figure className="m-0">
      <div
        className="relative rounded-xl border border-line bg-surface p-5 sm:p-7"
        style={{ boxShadow: "var(--shadow)" }}
      >
        {/* Both drafts live in the same grid cell, so the card never jumps as they swap. */}
        <div className="grid text-[0.95rem] leading-relaxed sm:text-base">
          <p
            className={`col-start-1 row-start-1 font-mono transition-all duration-500 ${
              rewritten ? "pointer-events-none opacity-0 blur-[2px]" : "opacity-100"
            }`}
          >
            <span
              className="box-decoration-clone bg-no-repeat transition-[background-size] duration-700 ease-out"
              style={{
                backgroundImage: "linear-gradient(var(--sel-wash), var(--sel-wash))",
                backgroundSize: highlighted ? "100% 100%" : "0% 100%",
              }}
            >
              {BEFORE}
            </span>
          </p>

          <p
            className={`col-start-1 row-start-1 transition-all duration-500 ${
              rewritten ? "opacity-100" : "pointer-events-none opacity-0 blur-[2px]"
            }`}
          >
            {AFTER}
          </p>
        </div>

        <div className="rule mt-5 flex items-center justify-between gap-4 pt-4">
          <span className="eyebrow" aria-live="polite">
            {CAPTION[phase]}
          </span>
          <Keys lit={keysLit} />
        </div>
      </div>

      <figcaption className="sr-only">
        A Slack message reading &ldquo;{BEFORE}&rdquo; is selected, the Command Shift R shortcut is
        pressed, and it is replaced in place with &ldquo;{AFTER}&rdquo;
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
          }}
        >
          {key}
        </kbd>
      ))}
    </span>
  );
}
