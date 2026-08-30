import fs from "node:fs";
import path from "node:path";

/*
  A printer's device, set in characters.

  Printed books end with a colophon carrying the printer's mark — so this page does too. The art
  is read at build time from tools/logo.txt, the same file the README and the build banner use,
  generated from the same drawing routine as the app icon. It cannot drift from the icon.

  Deliberately small and quiet: a device at the end of a book is a signature, not a billboard.
*/
function readMark(): string {
  try {
    return fs
      .readFileSync(path.join(process.cwd(), "..", "..", "tools", "logo.txt"), "utf8")
      .replace(/\s+$/, "");
  } catch {
    return ""; // the site must still build if the tools directory is not present
  }
}

export function ColophonMark() {
  const mark = readMark();
  if (!mark) return null;

  return (
    <pre
      aria-hidden="true"
      className="overflow-x-auto font-mono text-[0.34rem] leading-[1.05] text-muted/70 select-none sm:text-[0.42rem]"
    >
      {mark}
    </pre>
  );
}
