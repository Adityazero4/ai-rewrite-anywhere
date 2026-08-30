import fs from "node:fs";
import path from "node:path";
import { GITHUB } from "@/lib/site";

/*
  The mark, drawn in characters, printed to the browser console. This audience opens DevTools.
  The art is read from tools/logo.txt at build time — the same file the README and the build
  banner use, generated from the same drawing routine as the icon, so it can never drift.
*/
function readMark(): string {
  try {
    return fs.readFileSync(path.join(process.cwd(), "..", "..", "tools", "logo.txt"), "utf8").trimEnd();
  } catch {
    return ""; // the site must build even if the tools directory is not there
  }
}

export function ConsoleMark() {
  const mark = readMark();
  if (!mark) return null;

  const script = `console.log("%c"+${JSON.stringify(`\n${mark}\n`)},"color:#5c9bff");
console.log("%cRewrite anything, anywhere on your Mac.%c\\n${GITHUB}","color:#5c9bff;font-weight:600","color:inherit");`;

  return (
    <script
      // Build-time constant with no user input; `<` is escaped so it cannot close the tag.
      dangerouslySetInnerHTML={{ __html: script.replace(/</g, "\\u003c") }}
    />
  );
}
