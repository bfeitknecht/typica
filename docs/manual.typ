// typica v0.1.0 — Package Reference Manual (generated from source doc-comments via @preview/tidy)
#import "@preview/tidy:0.4.3"
#import "@preview/typica:0.1.0"
#import "@preview/typica:0.1.0": *

#let t = default-theme

#set document(
  title: "typica — Package Reference Manual",
  author: "Basil Feitknecht",
)

#set page(
  paper: "a4",
  margin: (top: 20mm, bottom: 20mm, left: 18mm, right: 66mm),
  fill: t.paper-light,
  header: context {
    if here().page() > 1 {
      set text(font: t.mono-fonts, size: 7.5pt, fill: t.muted-light)
      [typica v0.1.0 #h(1fr) Package Reference Manual]
      v(-0.45em)
      line(length: 100%, stroke: 0.45pt + t.border-light)
    }
  },
  footer: context {
    set text(font: t.mono-fonts, size: 7.5pt, fill: t.muted-light)
    line(length: 100%, stroke: 0.45pt + t.border-light)
    v(-0.35em)
    [https://github.com/bfeitknecht/typica #h(1fr) #counter(page).display(
        "1 / 1",
        both: true,
      )]
  },
)

#set text(font: t.serif-fonts, size: 10pt, fill: t.text-light, lang: "en")
#set par(leading: 0.68em, spacing: 1.15em, justify: false)
#show math.equation: set text(font: t.math-fonts)
#show raw: set text(font: t.mono-fonts, size: 0.84em)
#show raw.where(block: false): box.with(
  fill: t.surface-1-light,
  stroke: 0.45pt + t.border-light,
  inset: (x: 0.3em, y: 0pt),
  outset: (y: 0.16em),
  radius: 2pt,
)
#show link: it => underline(
  stroke: 0.5pt + t.muted-light,
  offset: 1.8pt,
  it,
)
#show: zebraw-init
#show: checklist.with(
  marker-map: (
    " ": move(dy: -0.08em, box(baseline: bottom, circle(
      radius: 0.22em,
      stroke: 0.65pt + t.muted-light,
    ))),
    "x": move(dy: -0.08em, box(baseline: bottom, circle(
      radius: 0.22em,
      stroke: 0.65pt + t.text-light,
      fill: t.text-light,
    ))),
  ),
)

#set heading(numbering: "1.1")
#show heading.where(level: 1): it => block(
  above: 1.9em,
  below: 0.9em,
  breakable: false,
  {
    if it.numbering != none {
      text(
        font: t.mono-fonts,
        size: 0.78em,
        weight: "regular",
        fill: t.muted-light,
        counter(heading).display("01"),
      )
      h(0.55em)
    }
    show raw.where(block: false): r => text(
      font: t.mono-fonts,
      size: 0.86em,
      r.text,
    )
    text(size: 1.38em, weight: "semibold", it.body)
    v(0.28em)
    line(length: 100%, stroke: 0.55pt + t.border-light)
  },
)
#show heading.where(level: 2): it => block(
  above: 1.45em,
  below: 0.65em,
  breakable: false,
  {
    if it.numbering != none {
      text(
        font: t.mono-fonts,
        size: 0.78em,
        weight: "regular",
        fill: t.muted-light,
        counter(heading).display(),
      )
      h(0.5em)
    }
    show raw.where(block: false): r => text(
      font: t.mono-fonts,
      size: 0.88em,
      r.text,
    )
    text(size: 1.12em, weight: "semibold", it.body)
  },
)

// ─── Monochrome `tidy` Style Matching `typica` ──────────────────────────────

#let _show-type(tp, style-args: (:)) = {
  box(
    fill: t.surface-2-light,
    stroke: 0.45pt + t.border-light,
    inset: (x: 0.3em, y: 0.12em),
    radius: 2pt,
    text(font: t.mono-fonts, size: 7.4pt, fill: t.muted-light, tp),
  )
}

#let _show-parameter-list(fn, style-args) = {
  block(
    width: 100%,
    fill: t.surface-1-light,
    stroke: 0.5pt + t.border-light,
    inset: (x: 0.65em, y: 0.5em),
    radius: 2pt,
    breakable: false,
    {
      set text(font: t.mono-fonts, size: 8.2pt, fill: t.text-light)
      text(weight: "bold", fn.name)
      "("
      let inline-args = fn.args.len() <= 3
      if not inline-args and fn.args.len() > 0 { "\n  " }
      let items = ()
      for (name, info) in fn.args {
        if style-args.omit-private-parameters and name.starts-with("_") {
          continue
        }
        let def-part = if "default" in info {
          ": " + text(fill: t.muted-light, info.default)
        } else {
          ""
        }
        let target-lbl = label(
          style-args.label-prefix + fn.name + "." + name.trim("."),
        )
        let linked-name = if (
          style-args.enable-cross-references
            and info.at("description", default: "") != ""
        ) {
          link(target-lbl, name)
        } else {
          name
        }
        items.push(linked-name + def-part)
      }
      items.join(if inline-args { ", " } else { ",\n  " })
      if not inline-args and fn.args.len() > 0 { ",\n" }
      ")"
      if fn.return-types != none {
        h(0.45em)
        text(fill: t.muted-light)[->]
        h(0.35em)
        fn.return-types.map(tp => _show-type(tp)).join([ ])
      }
    },
  )
}

#let _show-parameter-block(
  name,
  types,
  content,
  style-args,
  show-default: false,
  default: none,
  function-name: none,
) = block(
  width: 100%,
  above: 0.48em,
  below: 0.48em,
  breakable: style-args.break-param-descriptions,
  {
    set par(leading: 0.56em, spacing: 0.55em)
    text(
      font: t.mono-fonts,
      size: 8.3pt,
      weight: "bold",
      fill: t.text-light,
      name,
    )
    if function-name != none and style-args.enable-cross-references {
      [#box()#label(function-name + "." + name.trim("."))]
    }
    if types.len() > 0 {
      h(0.4em)
      types.map(tp => _show-type(tp)).join(h(0.22em))
    }
    if show-default {
      h(0.45em)
      text(font: t.mono-fonts, size: 7.6pt, fill: t.muted-light, "= " + default)
    }
    linebreak()
    pad(left: 0.9em, text(size: 9.2pt, content))
  },
)

#let _render-doc-example(raw-it) = {
  let code-str = raw-it.text.trim("\n")
  let preview = eval(code-str, mode: "markup", scope: dictionary(typica))
  block(
    width: 100%,
    above: 0.6em,
    below: 0.65em,
    breakable: false,
    stack(
      dir: ttb,
      spacing: 0pt,
      block(
        width: 100%,
        fill: t.surface-1-light,
        stroke: 0.5pt + t.border-light,
        inset: (x: 0.65em, y: 0.48em),
        radius: (top: 2pt, bottom: 0pt),
        raw(code-str, lang: "typ", block: true),
      ),
      block(
        width: 100%,
        fill: t.paper-light,
        stroke: (
          left: 0.5pt + t.border-light,
          right: 0.5pt + t.border-light,
          bottom: 0.5pt + t.border-light,
          top: none,
        ),
        inset: (x: 0.7em, y: 0.55em),
        radius: (top: 0pt, bottom: 2pt),
        preview,
      ),
    ),
  )
}

#let _show-function(fn, style-args) = block(
  width: 100%,
  above: 1.05em,
  below: 0.95em,
  stroke: (left: 1.3pt + t.frame-light),
  inset: (left: 0.85em, y: 0.1em),
  breakable: true,
  {
    show raw.where(lang: "example"): _render-doc-example
    _show-parameter-list(fn, style-args)
    if style-args.enable-cross-references {
      [#box()#label(style-args.label-prefix + fn.name + "()")]
    }
    if fn.description != "" {
      v(0.35em)
      tidy.utilities.eval-docstring(fn.description, style-args)
    }
    let param-blocks = ()
    for (name, info) in fn.args {
      if style-args.omit-private-parameters and name.starts-with("_") {
        continue
      }
      let desc = info.at("description", default: "")
      if desc == "" and style-args.omit-empty-param-descriptions {
        continue
      }
      param-blocks.push(_show-parameter-block(
        name,
        info.at("types", default: ()),
        tidy.utilities.eval-docstring(desc, style-args),
        style-args,
        show-default: "default" in info,
        default: info.at("default", default: none),
        function-name: style-args.label-prefix + fn.name,
      ))
    }
    if param-blocks.len() > 0 {
      v(0.4em)
      block(
        below: 0.25em,
        breakable: false,
        text(
          font: t.sans-fonts,
          size: 7.4pt,
          weight: "bold",
          tracking: 0.05em,
          fill: t.muted-light,
        )[PARAMETERS.],
      )
      param-blocks.join()
    }
  },
)

#let _show-variable(var, style-args) = block(
  width: 100%,
  above: 1.0em,
  below: 0.9em,
  stroke: (left: 1.3pt + t.frame-light),
  inset: (left: 0.85em, y: 0.1em),
  breakable: true,
  {
    block(
      width: 100%,
      fill: t.surface-1-light,
      stroke: 0.5pt + t.border-light,
      inset: (x: 0.65em, y: 0.5em),
      radius: 2pt,
      breakable: false,
      {
        text(
          font: t.mono-fonts,
          size: 8.2pt,
          weight: "bold",
          fill: t.text-light,
          var.name,
        )
        if style-args.enable-cross-references {
          [#box()#label(style-args.label-prefix + var.name)]
        }
        if "type" in var and var.type != none {
          h(0.5em)
          _show-type(var.type)
        }
      },
    )
    if var.description != "" {
      v(0.35em)
      tidy.utilities.eval-docstring(var.description, style-args)
    }
  },
)

#let typica-tidy-style = (
  show-outline: (module-doc, style-args: (:)) => none,
  show-type: _show-type,
  show-parameter-list: _show-parameter-list,
  show-parameter-block: _show-parameter-block,
  show-function: _show-function,
  show-variable: _show-variable,
  show-reference: (lbl, name, style-args: none) => link(lbl, raw(
    name,
    lang: none,
  )),
  show-example: (..args) => tidy.show-example.show-example(
    ..args,
    dir: ttb,
    scale-preview: 100%,
    layout: tidy.show-example.default-layout-example.with(
      dir: ttb,
      scale-preview: 100%,
      col-spacing: 0.45em,
      code-block: block.with(
        fill: t.surface-1-light,
        stroke: 0.5pt + t.border-light,
        inset: (x: 0.6em, y: 0.45em),
        radius: 2pt,
      ),
      preview-block: block.with(
        fill: t.paper-light,
        stroke: 0.5pt + t.border-light,
        inset: (x: 0.65em, y: 0.5em),
        radius: 2pt,
      ),
    ),
  ),
)

#let render-src-module(path, prefix) = {
  let parsed = tidy.parse-module(
    read(path),
    label-prefix: "typica-" + prefix + "-",
    scope: dictionary(typica),
  )
  tidy.show-module(
    parsed,
    style: typica-tidy-style,
    show-module-name: false,
    show-outline: false,
    omit-private-definitions: true,
    omit-private-parameters: true,
    break-param-descriptions: true,
    sort-functions: none,
  )
}

// ─── Title Block ─────────────────────────────────────────────────────────────

#block(width: 100%, below: 1.5em, {
  text(
    font: t.mono-fonts,
    size: 2.2em,
    weight: "bold",
    tracking: -0.03em,
  )[typica]
  h(0.65em)
  text(
    font: t.mono-fonts,
    size: 0.9em,
    fill: t.muted-light,
  )[v0.1.0 · Typst >= 0.15.1]
  v(0.35em)
  text(size: 1.14em, fill: t.muted-light, emph[
    Monochrome HTML blog bundles with native MathML, right-margin sidenotes, mathematical environments, and RSS / Atom syndication.
  ])
  v(0.75em)
  block(
    width: 100%,
    stroke: (top: 0.55pt + t.border-light, bottom: 0.55pt + t.border-light),
    inset: (y: 0.48em),
    {
      set text(font: t.mono-fonts, size: 8pt)
      grid(
        columns: (6.4em, 1fr),
        row-gutter: 0.34em,
        column-gutter: 0.9em,
        text(fill: t.muted-light)[import],
        [`#import "@preview/typica:0.1.0": *`],

        text(fill: t.muted-light)[scaffold],
        [`typst init @preview/typica:0.1.0 my-blog`],

        text(fill: t.muted-light)[bundle],
        [`typst compile --features html,bundle --format bundle site.typ public`],

        text(fill: t.muted-light)[license],
        [`MIT` (`src/`) · `MIT-0` (`template/`, `examples/`)],
      )
    },
  )
})

#outline(title: none, indent: 1.1em, depth: 2)

= Architecture & Compilation Targets

`typica` compiles a pure Typst project directly into a complete static blog without external static-site generators, client-side JavaScript frameworks, or manual MathML post-processing#sidenote[A 14-line event listener handles code-block copy buttons; every layout, sidenote toggle, and dark/light rule is pure HTML + CSS.].

Every post remains a valid standalone `.typ` document while `site.typ` mounts posts inline and emits the entire web root in a single compiler invocation:

#wide[
  #table(
    columns: (auto, auto, 1fr),
    stroke: (x, y) => (
      top: if y == 0 { 0.65pt + t.frame-light } else {
        0.45pt + t.border-light
      },
      bottom: 0.5pt + t.border-light,
      left: none,
      right: none,
    ),
    inset: (x: 0.55em, y: 0.48em),
    fill: (_, y) => if y == 0 { t.surface-1-light } else { none },
    align: (left + horizon, left + horizon, left + horizon),
    table.header(
      text(font: t.sans-fonts, size: 7.8pt, weight: "bold")[MODE],
      text(font: t.sans-fonts, size: 7.8pt, weight: "bold")[COMMAND],
      text(font: t.sans-fonts, size: 7.8pt, weight: "bold")[OUTPUT],
    ),
    [Full site (`bundle`)],
    [`typst compile --features html,bundle -f bundle site.typ public`],
    [`index.html`, `404.html`, `posts/<slug>/index.html`, assets, `css/style.css`, `rss.xml`, `atom.xml`],

    [Single post (`html`)],
    [`typst compile --features html -f html posts/fixed-points.typ`],
    [Self-contained HTML5 post with inlined `style.css`],

    [Live editor (`paged`)],
    [`typst watch posts/fixed-points.typ`],
    [Instant `height: auto` paged preview with right-margin sidenotes],

    [Archival print],
    [Browser #kbd("Ctrl+P") on any HTML post],
    [Two-column `@media print` layout preserving right-margin sidenotes on paper],
  )
]

= Project Layout & Optional Post Folders

Posts without external files live directly as flat `.typ` files (`posts/foo.typ`). When a post needs co-located images, SVGs, or downloadable files, place it in its own directory (`posts/bar/index.typ`) alongside those assets:

#zebraw(numbering: false)[
  ```text
  my-blog/
  ├── site.typ                  # Homepage (<site>), feeds, and mounted posts
  └── posts/
      ├── fixed-points.typ      # Flat post -> posts/fixed-points/index.html
      └── automaton/            # Optional folder when co-locating assets
          ├── index.typ         # -> posts/automaton/index.html
          └── dfa.svg           # -> posts/automaton/dfa.svg
  ```
]

Cross-references work across the entire bundle using standard Typst labels:
- `@site` (or `@site[home]`) links back to `index.html` from any post.
- `@fixed-points` links to `posts/fixed-points/index.html` using the post's formatted title.
- `@kleene-fp` jumps directly to section `= ... <kleene-fp>` inside whichever post defines it.
- `@rss[rss]` and `@atom[atom]` link to `rss.xml` and `atom.xml` on the homepage.

= Library Reference (Generated with `tidy`)

The reference sections below are parsed directly from `typica`'s source modules (`src/*.typ`) using `@preview/tidy:0.4.3`.

== Site Bundler (`src/site.typ`)
#render-src-module("../src/site.typ", "site")

== Post Template & Assets (`src/post.typ`)
#render-src-module("../src/post.typ", "post")

== Environments, Code & Layout (`src/components.typ`)
#render-src-module("../src/components.typ", "components")

== Margin Sidenotes (`src/notes.typ`)
#render-src-module("../src/notes.typ", "notes")

== Theme, Fonts & Stylesheet (`src/theme.typ`)

Passing `theme: (...)` to `site.with(...)` or `post.with(...)` overrides any subset of `default-theme` across *both* the generated HTML stylesheet (`css/style.css`) and paged Typst previews:

#wide[
  #table(
    columns: (auto, auto, 1fr),
    stroke: (x, y) => (
      top: if y == 0 { 0.65pt + t.frame-light } else {
        0.45pt + t.border-light
      },
      bottom: 0.5pt + t.border-light,
      left: none,
      right: none,
    ),
    inset: (x: 0.55em, y: 0.42em),
    fill: (_, y) => if y == 0 { t.surface-1-light } else { none },
    align: (left + horizon, left + horizon, left + horizon),
    table.header(
      text(font: t.sans-fonts, size: 7.8pt, weight: "bold")[KEY],
      text(font: t.sans-fonts, size: 7.8pt, weight: "bold")[DEFAULT],
      text(font: t.sans-fonts, size: 7.8pt, weight: "bold")[ROLE],
    ),
    [`paper-light` / `paper-dark`],
    [`oklch(99%, 0, 0deg)` / `oklch(18%, 0, 0deg)`],
    [Page background (`--bg`)],

    [`text-light` / `text-dark`],
    [`oklch(18%, 0, 0deg)` / `oklch(93%, 0, 0deg)`],
    [Primary ink (`--fg`)],

    [`muted-light` / `muted-dark`],
    [`oklch(52%, 0, 0deg)` / `oklch(65%, 0, 0deg)`],
    [Secondary metadata, captions, sidenotes (`--muted`)],

    [`border-light` / `border-dark`],
    [`oklch(89%, 0, 0deg)` / `oklch(29%, 0, 0deg)`],
    [Hairline dividers & code borders (`--line`)],

    [`frame-light` / `frame-dark`],
    [`oklch(20%, 0, 0deg)` / `oklch(84%, 0, 0deg)`],
    [Environment & `grid-table` outer frames (`--frame`)],

    [`surface-1-*` / `surface-2-*`],
    [`96.5%` & `93.5%` / `22%` & `26%`],
    [Code background, box headers, line highlights],

    [`serif-fonts`],
    [`("STIX Two Text", "Libertinus Serif")`],
    [Body prose, headings, and sidenotes (`--serif`)],

    [`math-fonts`],
    [`("STIX Two Math", "New Computer Modern Math")`],
    [Equations & native browser MathML (`--math`)],

    [`sans-fonts`],
    [`("Helvetica Neue", "Helvetica", "Arial", "DejaVu Sans")`],
    [Uppercase environment & proof labels (`--sans`)],

    [`mono-fonts`],
    [`("Commit Mono", "CommitMono", "DejaVu Sans Mono")`],
    [Code listings, frontmatter, tags, links row (`--mono`)],

    [`font-faces`],
    [`auto`],
    [Emits `@font-face` blocks for active default web fonts; pass custom CSS `str` or `none`],

    [`font-size`, `page-width`, `margin`],
    [`10.8pt`, `210mm`, `(left: 2.2cm, right: 7.4cm, ...)`],
    [Paged preview typography & sidenote margin geometry],
  )
]

#render-src-module("../src/theme.typ", "theme")

== Syndication Feeds (`src/feeds.typ`)
#render-src-module("../src/feeds.typ", "feeds")
