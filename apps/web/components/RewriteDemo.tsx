"use client";

import { useEffect, useState } from "react";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { EXAMPLES, draftOf, finalOf } from "@/lib/site";

/*
  The signature. This app is a copy-editor, so the hero is a proof being marked up: the draft
  comes in, the red pencil strikes what goes, the blue pencil writes what replaces it, and then
  the marks resolve into clean copy. That is literally what pressing the shortcut does.

  Three states, not a continuous animation — a proof has stages, and stages are legible.
*/

type Stage = "draft" | "marked" | "clean";

const NEXT: Record<Stage, { next: Stage; ms: number }> = {
  draft: { next: "marked", ms: 1400 },
  marked: { next: "clean", ms: 2600 },
  clean: { next: "draft", ms: 3000 },
};

const LABEL: Record<Stage, string> = {
  draft: "As typed",
  marked: "Marked up",
  clean: "Set clean",
};

export function RewriteDemo() {
  const [index, setIndex] = useState(0);
  const [stage, setStage] = useState<Stage>("draft");
  const [animate, setAnimate] = useState(false);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      setStage("marked"); // the marked-up state is the one that explains the product
      return;
    }
    setAnimate(true);
  }, []);

  useEffect(() => {
    if (!animate) return;
    const { next, ms } = NEXT[stage];
    const timer = setTimeout(() => {
      setStage(next);
      if (next === "draft") setIndex((i) => (i + 1) % EXAMPLES.length);
    }, ms);
    return () => clearTimeout(timer);
  }, [stage, animate]);

  const example = EXAMPLES[index];

  return (
    <figure className="m-0">
      <div className="sheet">
        {/* The proof's header: which manuscript this is, and its state. */}
        <div className="flex items-center justify-between gap-4 border-b border-rule px-5 py-2.5 sm:px-7">
          {/*
            Radix Tabs rather than hand-rolled buttons: it gives roving tabindex and arrow-key
            navigation for free, which a plain role="tablist" does not. Styled from scratch —
            the library is here for behaviour, never for its look.
          */}
          <Tabs
            value={String(index)}
            onValueChange={(v) => {
              setIndex(Number(v));
              setStage("draft");
            }}
          >
            <TabsList className="h-auto gap-3 bg-transparent p-0">
              {EXAMPLES.map((item, i) => (
                <TabsTrigger
                  key={item.app}
                  value={String(i)}
                  className="rounded-none border-0 bg-transparent px-0 py-0 font-mono text-[0.7rem] uppercase tracking-[0.12em] text-muted shadow-none transition-colors hover:text-ink data-[state=active]:bg-transparent data-[state=active]:text-ink data-[state=active]:shadow-none data-[state=active]:underline data-[state=active]:decoration-blue data-[state=active]:decoration-2 data-[state=active]:underline-offset-[6px]"
                >
                  {item.app}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>
          <span className="folio">{example.where}</span>
        </div>

        <div className="grid gap-0 sm:grid-cols-[3.25rem_1fr]">
          {/* Editor's margin — the mark that says what was done to this line. */}
          <div className="hidden items-start justify-center border-r border-rule pt-6 sm:flex">
            <span
              className="font-mono text-sm transition-colors duration-300"
              style={{ color: stage === "draft" ? "var(--muted)" : "var(--blue)" }}
              aria-hidden="true"
            >
              {stage === "draft" ? "¶" : stage === "marked" ? "✎" : "✓"}
            </span>
          </div>

          <div className="px-5 py-6 sm:px-7">
            <p className="font-serif text-[1.15rem] leading-[1.75] sm:text-[1.3rem]">
              {stage === "draft" && draftOf(example.marks)}

              {stage === "marked" &&
                example.marks.map((mark, i) =>
                  "keep" in mark ? (
                    <span key={i}>{mark.keep}</span>
                  ) : (
                    <span key={i}>
                      <span className="cut">{mark.cut}</span>
                      <span className="add">{mark.add}</span>
                    </span>
                  ),
                )}

              {stage === "clean" && finalOf(example.marks)}
            </p>

            <div className="mt-6 flex items-center justify-between gap-4 border-t border-rule pt-4">
              <span className="folio" aria-live="polite">
                {LABEL[stage]}
              </span>
              <Keys pressed={stage === "marked"} />
            </div>
          </div>
        </div>
      </div>

      <figcaption className="sr-only">
        A {example.app} message reading &ldquo;{draftOf(example.marks)}&rdquo; is marked up and
        reset as &ldquo;{finalOf(example.marks)}&rdquo;
      </figcaption>
    </figure>
  );
}

function Keys({ pressed }: { pressed: boolean }) {
  return (
    <span className="flex shrink-0 items-center gap-1" aria-hidden="true">
      {["⌘", "⇧", "R"].map((key) => (
        <kbd
          key={key}
          className="grid h-6 min-w-6 place-items-center rounded-[3px] border px-1.5 font-mono text-[0.7rem] transition-all duration-150"
          style={{
            borderColor: pressed ? "var(--blue)" : "var(--rule)",
            background: pressed ? "var(--blue-wash)" : "transparent",
            color: pressed ? "var(--blue)" : "var(--muted)",
            transform: pressed ? "translateY(1px)" : "none",
          }}
        >
          {key}
        </kbd>
      ))}
    </span>
  );
}
