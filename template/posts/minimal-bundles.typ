#import "@preview/typica:0.1.0": *

#show: post.with(
  title: [Minimal Static Sites from Pure Typst],
  subtitle: [HTML-only bundles, cross-post references, and print-first monochrome CSS],
  author: "Ada Lovelace",
  monograph: "EWD-01",
  created: datetime(year: 2026, month: 10, day: 18),
  modified: datetime(year: 2026, month: 10, day: 19),
  summary: [Why every page in a technical blog only needs clean semantic HTML, one monochrome stylesheet, and native Typst labels.],
  tags: ("typst", "systems", "web"),
)

Static site generators have a habit of accumulating configuration layers, JavaScript bundlers, and brittle template DSLs#sidenote[A blog whose build pipeline outlives its prose has inverted its priorities.]. With Typst's `bundle` target, each article remains a standalone `.typ` file while `site.typ` compiles the entire site -- custom homepage, articles, CSS, and feeds -- in a single compiler invocation.

Cross-references work natively across files: writing `@fixed-points` links to @fixed-points, while `@kleene-fp` jumps straight to @kleene-fp inside that article.

= HTML-Only Pages & Print-First Design <html-only>

Every page in the bundle is emitted purely as semantic HTML5 with native browser MathML. Readers who want an offline or archival PDF simply press #kbd("Ctrl+P"): a dedicated `@media print` stylesheet preserves the two-column prose + right-margin sidenote geometry on paper.

- [x] Perceptual `oklch` & `oklab` monochrome palette across light, dark, and print
- [x] _STIX Two_ (prose & math), _Helvetica Neue_, and _Commit Mono_ (all configurable via `theme`)
- [x] Obsidian-style frontmatter properties (`author`, optional `monograph`, `created`, `modified`, `words`, `reading`, `tags`)
- [x] `spicky`-style `definition`, `theorem`, `example`, `recipe`, and `grid-table` wrappers
- [ ] Client-side JavaScript bundlers, trackers, or duplicate PDF downloads

= Compilation Modes at a Glance <modes>

When a table or figure benefits from the full width of prose plus margin, wrap it in `#wide[...]`:

#wide[
  #tablem[
    | *Command* | *Target* | *Result* |
    | :--- | :--- | :--- |
    | `typst compile --features html,bundle -f bundle site.typ public` | `bundle` | Custom `index.html` + `posts/` + `style.css` + `rss.xml` / `atom.xml` |
    | `typst compile --features html -f html posts/fixed-points.typ` | `html` | Self-contained single-file HTML post |
    | `typst watch posts/fixed-points.typ` | `paged` | Instant `height: auto` editor preview |
  ]
]

#example[Single-Source Fan-Out][
  Vector diagrams authored in Typst render natively in editor previews and as crisp inline `<svg>` in HTML (automatically inverted in dark mode):

  #diagram(
    caption: [One Typst source tree compiling to static HTML, monochrome CSS, and RSS / Atom feeds.],
  )[
    #set text(
      font: default-theme.mono-fonts,
      size: 8.5pt,
      fill: default-theme.text-light,
    )
    #let node(lbl) = box(
      fill: default-theme.surface-1-light,
      stroke: 0.75pt + default-theme.frame-light,
      inset: (x: 0.75em, y: 0.48em),
      radius: 2.5pt,
      lbl,
    )
    #grid(
      columns: 5,
      gutter: 0.65em,
      align: horizon,
      node[`posts/*.typ`],
      $->$,
      node[`site.typ`],
      $->$,
      node[`HTML + style.css + rss / atom`],
    )
  ]
]

Return to @site[`folio`].
