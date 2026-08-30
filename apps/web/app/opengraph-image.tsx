import { ImageResponse } from "next/og";
import { NAME } from "@/lib/site";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = `${NAME} — rewrite any text, in any Mac app`;

/*
  The card shows the product's actual value — a scrappy draft becoming a clean sentence — rather
  than the keyboard chord. Deliberate: Satori has no font covering ⌘ and ⇧ and falls back to tofu,
  and the before/after is a stronger preview than a shortcut anyway.
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
          background: "#0a0d11",
          color: "#e8edf3",
          padding: 68,
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 14, color: "#8a94a3", fontSize: 25 }}>
          <div style={{ display: "flex", width: 13, height: 13, borderRadius: 4, background: "#5c9bff" }} />
          {NAME}
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 26 }}>
          <div style={{ display: "flex", fontSize: 72, letterSpacing: -2.5, lineHeight: 1.05 }}>
            Fix your writing where you wrote it.
          </div>

          {/* before → after, the whole product in one line each */}
          <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 4 }}>
            <div
              style={{
                display: "flex",
                fontSize: 26,
                color: "#8a94a3",
                background: "rgba(92,155,255,0.16)",
                borderRadius: 8,
                padding: "10px 14px",
                alignSelf: "flex-start",
                maxWidth: 1010,
              }}
            >
              can u check the deploy when ur free? not urgent but blocking me
            </div>
            <div style={{ display: "flex", fontSize: 26, color: "#e8edf3", padding: "0 14px", maxWidth: 1010 }}>
              Could you take a look at the deploy when you get a chance? Not urgent, but it is blocking me.
            </div>
          </div>
        </div>

        <div style={{ display: "flex", fontSize: 25, color: "#8a94a3" }}>
          One shortcut, any app · Free and open source · macOS 13+
        </div>
      </div>
    ),
    size,
  );
}
