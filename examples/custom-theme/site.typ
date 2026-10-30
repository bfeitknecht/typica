#import "@preview/typica:0.1.0": *

#show: site.with(
  title: "custom-theme",
  description: "Overriding font stacks and warm-paper oklch tokens via theme.",
  url: "https://theme.example.org",
  author: "Ada Lovelace",
  theme: (
    // Custom warm monochrome paper & ink in perceptual oklch
    paper-light: oklch(98%, 0.008, 85deg),
    surface-1-light: oklch(95%, 0.01, 85deg),
    surface-2-light: oklch(91.5%, 0.012, 85deg),
    paper-dark: oklch(17%, 0.006, 85deg),
    // Custom prose/math stacks propagate to both HTML CSS and paged PDF
    serif-fonts: ("Libertinus Serif", "STIX Two Text"),
    math-fonts: ("STIX Two Math",),
  ),
)

= Warm Paper Theme

Demonstrating `site.with(theme: (...))` font and palette overrides.

#links-row(
  [@rss[rss]],
  [@atom[atom]],
)

== Posts

#post(include "posts/custom-fonts.typ") <custom-fonts>
