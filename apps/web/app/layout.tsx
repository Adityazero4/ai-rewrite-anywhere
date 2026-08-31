import type { Metadata } from "next";
import { IBM_Plex_Mono, IBM_Plex_Sans, Instrument_Serif } from "next/font/google";
import { ConsoleMark } from "@/components/ConsoleMark";
import { CATEGORY, FAQ, NAME, SITE_URL } from "@/lib/site";
import "./globals.css";

/*
  Three roles, because the page has three voices. Instrument Serif is the prose being edited —
  high-contrast, editorial, the voice of the manuscript. IBM Plex Sans carries the explanation
  around it. IBM Plex Mono is the editor's hand: folios, marks, keycaps.
*/
const editorial = Instrument_Serif({
  variable: "--font-editorial",
  subsets: ["latin"],
  weight: "400",
  style: ["normal", "italic"],
  display: "swap",
});
const body = IBM_Plex_Sans({
  variable: "--font-body",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  display: "swap",
});
const marks = IBM_Plex_Mono({
  variable: "--font-marks",
  subsets: ["latin"],
  weight: ["400", "500"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: `${NAME} — ${CATEGORY}`,
    template: `%s · ${NAME}`,
  },
  description:
    "Pencil Mark is a free macOS menu-bar app that copy-edits your writing in place. Select text in any app, press ⌘⇧R, and it is rewritten — or fix grammar, make it concise, make it professional. Your OpenAI key, your Mac, nothing stored.",
  keywords: [
    "AI writing assistant for Mac",
    "rewrite text macOS shortcut",
    "system-wide AI rewrite tool",
    "fix grammar keyboard shortcut Mac",
    "macOS menu bar writing app",
    "AI proofreader for Slack",
    "open source Grammarly alternative Mac",
    "rewrite selected text anywhere",
  ],
  applicationName: NAME,
  authors: [{ name: "Aditya Jain", url: "https://github.com/Adityazero4" }],
  creator: "Aditya Jain",
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: SITE_URL,
    siteName: NAME,
    title: `${NAME} — ${CATEGORY}`,
    description:
      "Select any text on your Mac, press a shortcut, and Pencil Mark marks it up and sets it clean. Free and open source.",
  },
  twitter: {
    card: "summary_large_image",
    title: `${NAME} — ${CATEGORY}`,
    description:
      "Select any text on your Mac, press a shortcut, and Pencil Mark marks it up and sets it clean.",
  },
  category: "technology",
};

/*
  Structured data. No aggregateRating: there are no real reviews yet, and inventing them is both
  dishonest and precisely what Google penalises. It goes in when real ratings exist.
*/
const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "SoftwareApplication",
      name: NAME,
      applicationCategory: "UtilitiesApplication",
      applicationSubCategory: "Writing",
      operatingSystem: "macOS 13.0 or later",
      url: SITE_URL,
      downloadUrl: `${SITE_URL}#install`,
      softwareVersion: "1.0.0",
      license: "https://opensource.org/licenses/MIT",
      isAccessibleForFree: true,
      offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
      author: { "@type": "Person", name: "Aditya Jain", url: "https://github.com/Adityazero4" },
      description:
        "Pencil Mark is a macOS menu-bar app that copy-edits the text you have selected in any application, in place, using a global keyboard shortcut.",
      featureList: [
        "Copy-edit selected text in place in any macOS app",
        "Fix grammar, make concise, or make professional",
        "Configurable global keyboard shortcuts",
        "Translates non-English text into English",
        "API key stored in the macOS Keychain",
      ],
    },
    {
      "@type": "FAQPage",
      mainEntity: FAQ.map(({ q, a }) => ({
        "@type": "Question",
        name: q,
        acceptedAnswer: { "@type": "Answer", text: a },
      })),
    },
  ],
};

/*
  The payload is a compile-time constant with no user input, but `</script>` inside any future
  string would still break out of the tag. Escaping `<` costs nothing and removes the hazard.
*/
const structuredDataJSON = JSON.stringify(structuredData).replace(/</g, "\\u003c");

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={`${editorial.variable} ${body.variable} ${marks.variable} font-sans antialiased`}>
        {children}
        <ConsoleMark />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: structuredDataJSON }}
        />
      </body>
    </html>
  );
}
