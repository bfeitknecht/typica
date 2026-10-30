#import "@preview/typica:0.1.0": *

#show: site.with(
  title: `notes`,
  description: "Minimal single-post example for typica.",
  url: "https://notes.example.org",
  author: "Ada Lovelace",
)

Minimal technical blog compiled from pure Typst.

#links-row(
  link("https://example.org")[example.org],
  [@rss[rss]],
  [@atom[atom]],
)

== Posts

#post(include "posts/lambda-calculus.typ") <lambda-calculus>
