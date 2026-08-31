"use client";

import { useEffect, useState } from "react";

/*
  Three states, cycled by one control: Auto follows the system, Light and Dark override it.

  Hand-rolled rather than pulled from a library — it is a dozen lines of state plus one attribute,
  and the control has to read as part of the proof sheet rather than a stock sun/moon button.

  The stored choice is applied by an inline script in the document head before first paint, so
  there is no flash of the wrong theme. This component only mirrors and updates it.
*/

const CHOICES = ["auto", "light", "dark"] as const;
type Choice = (typeof CHOICES)[number];

const STORAGE_KEY = "theme";

const GLYPH: Record<Choice, string> = {
  auto: "◐",
  light: "○",
  dark: "●",
};

export function ThemeToggle() {
  // Start at "auto" on both server and client so hydration matches, then correct in the effect.
  const [choice, setChoice] = useState<Choice>("auto");
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let stored: string | null = null;
    try {
      stored = localStorage.getItem(STORAGE_KEY);
    } catch {
      // Private windows and blocked site data both throw; auto is the right fallback.
    }
    if (stored === "light" || stored === "dark") setChoice(stored);
    setReady(true);
  }, []);

  const apply = (next: Choice) => {
    setChoice(next);
    const root = document.documentElement;

    if (next === "auto") {
      delete root.dataset.theme;
    } else {
      root.dataset.theme = next;
    }

    try {
      if (next === "auto") localStorage.removeItem(STORAGE_KEY);
      else localStorage.setItem(STORAGE_KEY, next);
    } catch {
      // Not being able to remember the choice is survivable; applying it is what matters.
    }
  };

  const next = CHOICES[(CHOICES.indexOf(choice) + 1) % CHOICES.length];

  return (
    <button
      type="button"
      onClick={() => apply(next)}
      aria-label={`Theme: ${choice}. Switch to ${next}.`}
      title={`Theme: ${choice} — click for ${next}`}
      className="flex items-center gap-1.5 text-muted transition-colors hover:text-ink"
      // Until the stored choice is read, the label could disagree with the painted theme.
      style={{ visibility: ready ? "visible" : "hidden" }}
    >
      <span aria-hidden="true" className="w-[0.85rem] text-center text-[0.85rem] leading-none">
        {GLYPH[choice]}
      </span>

      {/*
        All three labels occupy the same grid cell, so the control is always as wide as the
        longest word. Sizing to the active label instead would move the whole nav every time
        the theme changed — "light" is wider than "auto" and "dark".
      */}
      <span className="hidden sm:grid">
        {CHOICES.map((option) => (
          <span
            key={option}
            aria-hidden={option !== choice}
            className="col-start-1 row-start-1 text-left"
            style={{ visibility: option === choice ? "visible" : "hidden" }}
          >
            {option}
          </span>
        ))}
      </span>
    </button>
  );
}
