#import "@preview/typica:0.1.0": *

#show: site.with(
  description: "Notes on programming languages, formal methods, and systems.",
  url: "https://blog.example.org",
  author: "Ada Lovelace",
)

= `folio`

Notes on programming languages, formal methods, mathematics, and systems.

#links-row(
  link("https://example.org")[example.org],
  link("https://github.com/example")[github],
  [@rss[rss]],
  [@atom[atom]],
)

== Posts

#post(include "posts/fixed-points.typ") <fixed-points>
#post(include "posts/minimal-bundles.typ") <minimal-bundles>
