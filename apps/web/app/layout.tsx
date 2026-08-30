import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { ConsoleMark } from "@/components/ConsoleMark";
import { FAQ, NAME, SITE_URL } from "@/lib/site";
import "./globals.css";

const sans = Geist({ variable: "--font-geist-sans", subsets: ["latin"], display: "swap" });
const mono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"], display: "swap" });

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: `${NAME} — AI writing assistant for macOS that works in every app`,
    template: `%s · ${NAME}`,
  },
  description:
    "Select text in any Mac app and press ⌘⇧R to rewrite it, fix grammar, make it concise, or make it professional. A free, open-source menu-bar app. Your OpenAI key, your Mac, nothing stored.",
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
    title: `${NAME} — rewrite any text, in any Mac app`,
    description:
      "Select text anywhere on your Mac, press a shortcut, and it is replaced with a cleaner version. Free and open source.",
  },
  twitter: {
    card: "summary_large_image",
    title: `${NAME} — rewrite any text, in any Mac app`,
    description:
      "Select text anywhere on your Mac, press a shortcut, and it is replaced with a cleaner version.",
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
        "A macOS menu-bar app that rewrites the text you have selected in any application, in place, using a global keyboard shortcut.",
      featureList: [
        "Rewrite selected text in any macOS app",
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
      <body className={`${sans.variable} ${mono.variable} font-sans antialiased`}>
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
