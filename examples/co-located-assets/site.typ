#import "@preview/typica:0.1.0": *

#show: site.with(
  title: "assets-demo",
  description: "Co-locating SVG assets inside an optional post directory.",
  url: "https://assets.example.org",
  author: "Ada Lovelace",
)

= `assets-demo`

Posts without assets stay flat (`posts/*.typ`); posts with assets use a folder (`posts/<slug>/index.typ`).

#links-row(
  [@rss[rss]],
  [@atom[atom]],
)

== Posts

#post(include "posts/state-machine/index.typ") <state-machine>
