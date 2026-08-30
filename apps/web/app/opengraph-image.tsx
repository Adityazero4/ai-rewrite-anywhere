import { ImageResponse } from "next/og";
import { NAME } from "@/lib/site";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = `${NAME} — fix your writing in place`;

/*
  The card is a proof sheet: the draft struck in red pencil, the correction set in blue beneath.
  No ⌘/⇧ glyphs — Satori has no font covering them and renders tofu — and the marked-up line
  explains the product better than a keyboard chord anyway.
*/
export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "#ffffff",
          color: "#14141a",
          padding: "60px 68px",
          fontFamily: "Georgia, serif",
          borderLeft: "18px solid #14141a",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            fontSize: 21,
            color: "#6b6b76",
            letterSpacing: 2,
            textTransform: "uppercase",
          }}
        >
          <span>{NAME}</span>
          <span>Proof · rev. 1.0</span>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 34 }}>
          <div style={{ display: "flex", fontSize: 82, lineHeight: 1.05, letterSpacing: -1.5 }}>
            Fix your writing in place.
          </div>

          {/* The correction itself, set the way the site sets it. */}
          <div style={{ display: "flex", flexDirection: "column", gap: 10, fontSize: 30 }}>
            <div style={{ display: "flex" }}>
              <span
                style={{
                  color: "#c8342b",
                  textDecoration: "line-through",
                  background: "rgba(200,52,43,0.09)",
                  padding: "2px 6px",
                }}
              >
                can u check the deploy when ur free? not urgent but blocking me
              </span>
            </div>
            <div style={{ display: "flex" }}>
              <span
                style={{
                  color: "#1f4fd8",
                  background: "rgba(31,79,216,0.09)",
                  borderBottom: "2px solid #1f4fd8",
                  padding: "2px 6px",
                }}
              >
                Could you take a look at the deploy when you get a chance? Not urgent, but it is
                blocking me.
              </span>
            </div>
          </div>
        </div>

        <div style={{ display: "flex", fontSize: 21, color: "#6b6b76", letterSpacing: 1 }}>
          One shortcut, any Mac app · Free and open source · macOS 13+
        </div>
      </div>
    ),
    size,
  );
}
