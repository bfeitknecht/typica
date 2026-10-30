// Post authoring template (`#show: post.with(...)`), inline mounting (`#post(include ...)`),
// co-located post assets (`assets: (...)` / `#post-asset(...)`), and paged preview styling.

#import "@preview/cheq:0.4.0": checklist
#import "@preview/zebraw:0.6.3": zebraw-init
#import "html.typ": render-html-shell
#import "notes.typ": reset-sidenotes, sidenote, sidenote-bottom-guard
#import "refs.typ": (
  date-sort-key, find-post-doc, format-date, slug-from-path, with-smart-refs,
)
#import "theme.typ": default-theme, resolve-theme
#import "words.typ": count-words, estimate-reading-minutes, query-body-words

#let _paged-sec-counter = counter("typica/paged-sec")

// Normalize `assets` passed to `post.with(assets: ...)` into an array of `(path, data, label)` dicts.
#let _normalize-post-assets(assets) = {
  if assets == none or assets == () or assets == (:) {
    ()
  } else if type(assets) == dictionary {
    assets
      .pairs()
      .map(((p, d)) => (path: str(p).trim("/"), data: d, label: none))
  } else if type(assets) == array {
    assets.map(a => (
      path: str(a.path).trim("/"),
      data: a.data,
      label: a.at("label", default: none),
    ))
  } else {
    panic(
      "`post.with(assets: ...)` expects a dictionary or an array of `(path, data, label?)` records.",
    )
  }
}

/// Declare a co-located file asset inline inside a post body
/// (`#post-asset("dfa.svg", read("dfa.svg", encoding: none)) <dfa>`).
/// In bundle mode, `site` emits the file alongside the post's `index.html` (`posts/<slug>/<path>`).
/// -> content
#let post-asset(
  /// Relative target filename inside the post's output directory.
  /// -> str
  path,
  /// Raw binary `bytes` (`read(..., encoding: none)`) or UTF-8 string payload.
  /// -> bytes | str
  data,
) = metadata((
  typica-post-asset: true,
  path: str(path).trim("/"),
  data: data,
))

// Extract `<typica-post-meta>` dictionary synchronously from an included post's content tree.
#let extract-post-meta(c) = {
  if type(c) != content {
    return none
  }
  if (
    c.func() == metadata and c.at("label", default: none) == <typica-post-meta>
  ) {
    return c.value
  }
  if c.has("child") {
    let r = extract-post-meta(c.child)
    if r != none { return r }
  }
  if c.has("body") {
    let r = extract-post-meta(c.body)
    if r != none { return r }
  }
  if c.has("children") {
    for ch in c.children {
      let r = extract-post-meta(ch)
      if r != none { return r }
    }
  }
  none
}

// Extract all inline `#post-asset(...)` metadata records synchronously from a post's content tree.
#let extract-post-assets(c) = {
  if type(c) != content {
    return ()
  }
  if (
    c.func() == metadata
      and type(c.value) == dictionary
      and c.value.at("typica-post-asset", default: false)
  ) {
    return (
      (
        path: c.value.path,
        data: c.value.data,
        label: c.at("label", default: none),
      ),
    )
  }
  let out = ()
  if c.has("child") {
    out += extract-post-assets(c.child)
  }
  if c.has("body") {
    out += extract-post-assets(c.body)
  }
  if c.has("children") {
    for ch in c.children {
      out += extract-post-assets(ch)
    }
  }
  out
}

/// Query all non-draft, non-unlisted `<typica-post-meta>` records across an HTML bundle,
/// sorted newest-first with resolved `slug`, `words`, `minutes`, `doc-loc`, and `html-path`.
/// Must be called inside `context`.
/// -> array
#let query-all-posts() = {
  let docs = query(document)
  let entries = ()
  for d in docs {
    if d.path != none and d.path.ends-with(".html") {
      let metas = query(selector(<typica-post-meta>).within(d.location()))
      if metas.len() > 0 {
        let m = metas.first().value
        if (
          not m.at("draft", default: false)
            and not m.at("unlisted", default: false)
        ) {
          let derived-slug = if m.slug != none { m.slug } else {
            slug-from-path(d.path)
          }
          let hint-words = query(
            selector(<typica-word-hint>).within(d.location()),
          ).fold(0, (acc, h) => acc + h.value)
          let total-words = m.base-words + hint-words
          entries.push((
            ..m,
            slug: derived-slug,
            words: total-words,
            minutes: estimate-reading-minutes(total-words, wpm: m.wpm),
            doc-loc: d.location(),
            doc-path: d.path,
            html-path: d.path,
          ))
        }
      }
    }
  }
  entries.sorted(key: p => p.sort-key).rev()
}

// Apply theme-driven `oklch` monochrome typography to paged previews.
#let style-paged-article(theme-cfg, numbered-headings: true, body) = {
  set text(
    font: theme-cfg.serif-fonts,
    size: theme-cfg.font-size,
    fill: theme-cfg.text-light,
    lang: "en",
  )
  set par(
    leading: 0.68em,
    spacing: 1.12em,
    justify: false,
  )

  show math.equation: set text(font: theme-cfg.math-fonts)
  show raw: set text(font: theme-cfg.mono-fonts, size: 0.84em)
  show raw.where(block: false): box.with(
    fill: theme-cfg.surface-1-light,
    stroke: 0.45pt + theme-cfg.border-light,
    inset: (x: 0.3em, y: 0.12em),
    outset: (y: 0.12em),
    radius: 2pt,
  )
  show raw.where(block: true): block.with(
    width: 100%,
    fill: theme-cfg.surface-1-light,
    stroke: 0.55pt + theme-cfg.border-light,
    inset: (x: 0.9em, y: 0.75em),
    radius: 2.5pt,
  )

  show link: it => {
    if type(it.dest) in (str, location, label) {
      underline(stroke: 0.5pt + theme-cfg.muted-light, offset: 2pt, text(
        fill: theme-cfg.text-light,
        it,
      ))
    } else {
      it
    }
  }

  show heading: set text(
    font: theme-cfg.serif-fonts,
    fill: theme-cfg.text-light,
  )
  show heading.where(level: 1): it => {
    if numbered-headings {
      _paged-sec-counter.step()
    }
    block(
      width: 100%,
      above: 1.85em,
      below: 0.78em,
      inset: (bottom: 0.38em),
      stroke: (bottom: 0.55pt + theme-cfg.border-light),
      context {
        if numbered-headings {
          let n = _paged-sec-counter.get().first()
          let pad = if n < 10 { "0" + str(n) } else { str(n) }
          text(
            font: theme-cfg.mono-fonts,
            size: 0.78em,
            weight: "regular",
            fill: theme-cfg.muted-light,
            pad,
          )
          h(0.55em)
        }
        text(size: 1.38em, weight: "semibold", it.body)
      },
    )
  }
  show heading.where(level: 2): it => block(above: 1.35em, below: 0.55em, {
    text(size: 1.14em, weight: "semibold", it.body)
  })
  show heading.where(level: 3): it => block(above: 1.1em, below: 0.45em, {
    text(size: 1.02em, weight: "semibold", emph(it.body))
  })

  show quote.where(block: true): it => block(
    width: 100%,
    inset: (left: 1em, y: 0.2em),
    stroke: (left: 1.5pt + theme-cfg.text-light),
    above: 1.1em,
    below: 1.1em,
    {
      emph(text(fill: theme-cfg.muted-light, it.body))
      if it.attribution != none {
        v(0.3em)
        align(right, text(
          font: theme-cfg.mono-fonts,
          size: 0.78em,
          fill: theme-cfg.muted-light,
          "- " + it.attribution,
        ))
      }
    },
  )

  set table(
    stroke: (_, y) => (
      top: if y == 0 { 1pt + theme-cfg.text-light } else if y == 1 {
        0.6pt + theme-cfg.text-light
      } else { none },
      bottom: 1pt + theme-cfg.text-light,
    ),
    inset: (x: 0.65em, y: 0.46em),
  )
  show table.cell.where(y: 0): set text(weight: "semibold")

  body
}

/// Dual-purpose post template and inline homepage mounter:
/// - In a post file (`posts/foo.typ` or `posts/foo/index.typ`):
///   `#show: post.with(title: [...], author: "...", created: ..., modified: ...)`
/// - In `site.typ`:
///   `#post(include "posts/foo.typ") <foo>` (or `"posts/foo/index.typ"` when co-locating assets)
/// -> content
#let post(
  /// Post title (`<h1>` in HTML, semibold heading in paged mode); `auto` detects an included post in `site.typ`.
  /// -> auto | content | str
  title: auto,
  /// Optional italic subtitle beneath `title` (also used as fallback summary).
  /// -> content | str | none
  subtitle: none,
  /// Creation date (`YYYY-MM-DD`); drives feed publication timestamps and newest-first sort order.
  /// -> datetime | str | none
  created: none,
  /// Last-modified date (`YYYY-MM-DD`); drives Atom `<updated>`.
  /// -> datetime | str | none
  modified: none,
  /// Alias for `created`.
  /// -> datetime | str | none
  date: none,
  /// Alias for `modified`.
  /// -> datetime | str | none
  updated: none,
  /// Post author; falls back to `site.with(author: ...)` inside a bundle.
  /// -> content | str | none
  author: none,
  /// Optional EWD-style monograph code (e.g. `"EWD-02"`) rendered right beneath `author` in post frontmatter.
  /// -> content | str | none
  monograph: none,
  /// Plain `#tag` strings rendered in `Commit Mono` and exported as RSS / Atom `<category>`.
  /// -> array
  tags: (),
  /// Short abstract displayed on homepage entry cards and in RSS / Atom feeds.
  /// -> content | str | none
  summary: none,
  /// Co-located files (`("dfa.svg": read("dfa.svg", encoding: none))`) emitted into `posts/<slug>/`.
  /// -> dictionary | array
  assets: (),
  /// Explicit slug override; defaults to the `<label>` attached to `#post(...) <slug>`.
  /// -> auto | str
  slug: auto,
  /// Optional custom bundle output path when mounting in `site.typ` (defaults to `<posts-dir>/<slug>/index.html`).
  /// -> str | none
  path: none,
  /// Backlink label at the top of HTML post pages (automatically omitted in PDF and `@media print`).
  /// -> content | str | none
  home-text: "/..",
  /// Words-per-minute reading speed used to compute `reading` minutes.
  /// -> int
  wpm: 200,
  /// Display `words` and `reading` rows in the post frontmatter block.
  /// -> bool
  show-wordcount: true,
  /// Exclude post from homepage listings and RSS / Atom feeds when `true`.
  /// -> bool
  draft: false,
  /// Emit the HTML page at its URL, but omit it from homepage listings and feeds.
  /// -> bool
  unlisted: false,
  /// Prefix top-level `=` sections with `01`, `02`, ... in `Commit Mono`.
  /// -> bool
  numbered-headings: true,
  /// Automatically route standard `#footnote[...]` calls into the right margin.
  /// -> bool
  footnotes-as-sidenotes: true,
  /// Per-post theme overrides layered onto the active site theme.
  /// -> dictionary
  theme: (:),
  /// Paged preview width override (`auto` uses `theme.page-width`).
  /// -> auto | length
  page-width: auto,
  /// Paged preview margin override (`auto` uses `theme.margin`).
  /// -> auto | dictionary
  margin: auto,
  /// Post body markup (when used via `#show: post.with(...)`) or `include "posts/..."` content (when mounted in `site.typ`).
  /// -> content
  body,
) = {
  let detected-meta = if title == auto { extract-post-meta(body) } else { none }
  if detected-meta != none {
    return metadata((
      typica-mounted-post: true,
      slug: if slug == auto { detected-meta.slug } else { slug },
      path: path,
      meta: detected-meta,
      body: body,
    ))
  }

  let title = if title == auto { [Untitled Post] } else { title }
  let explicit-slug = if slug == auto { none } else { slug }
  let eff-created = if created != none { created } else { date }
  let eff-modified = if modified != none { modified } else { updated }
  let created-str = format-date(eff-created)
  let modified-str = format-date(eff-modified)
  let base-words = count-words(body)
  let norm-assets = _normalize-post-assets(assets) + extract-post-assets(body)

  let meta-payload = (
    title: title,
    subtitle: subtitle,
    created: eff-created,
    created-str: created-str,
    modified: eff-modified,
    modified-str: modified-str,
    sort-key: date-sort-key(eff-created),
    author: author,
    monograph: monograph,
    tags: tags,
    summary: summary,
    assets: norm-assets,
    slug: explicit-slug,
    base-words: base-words,
    wpm: wpm,
    draft: draft,
    unlisted: unlisted,
  )

  [#metadata(meta-payload) <typica-post-meta>]
  reset-sidenotes()
  _paged-sec-counter.update(0)

  set footnote.entry(separator: if footnotes-as-sidenotes { none } else {
    line(length: 30%, stroke: 0.5pt)
  })
  show footnote.entry: it => if footnotes-as-sidenotes { none } else { it }
  show footnote: fn => if footnotes-as-sidenotes { sidenote(fn.body) } else {
    fn
  }

  context {
    let my-metas = query(selector(<typica-post-meta>).before(here()))
    let enc-doc = if my-metas.len() > 0 {
      find-post-doc(my-metas.last().location())
    } else {
      none
    }
    let doc-path = if enc-doc != none { enc-doc.path } else { none }
    let site-cfgs = query(<typica-site-cfg>)
    let site-cfg = if site-cfgs.len() > 0 { site-cfgs.first().value } else {
      none
    }
    let base-theme = if site-cfg != none { site-cfg.theme } else {
      default-theme
    }
    let merged-theme = resolve-theme(
      base-theme + (if theme == none { (:) } else { theme }),
    )
    let site-title = if site-cfg != none { site-cfg.title } else { none }
    let eff-author = if author != none {
      author
    } else if site-cfg != none {
      site-cfg.author
    } else {
      none
    }
    let has-props = (
      eff-author != none
        or monograph != none
        or created-str != none
        or modified-str != none
        or show-wordcount
        or tags.len() > 0
    )

    if target() == "html" {
      let home-docs = query(<site>)

      render-html-shell(
        title: title,
        site-title: site-title,
        description: if summary != none { summary } else { subtitle },
        author: eff-author,
        doc-path: doc-path,
        theme-cfg: merged-theme,
        include-feeds: false,
        {
          html.elem(
            "article",
            attrs: if numbered-headings { (class: "numbered-sections") } else {
              (:)
            },
            {
              if home-text != none {
                html.elem("nav", attrs: (class: "back-home"), {
                  if home-docs.len() > 0 {
                    link(home-docs.first().location(), home-text)
                  } else {
                    home-text
                  }
                })
              }

              html.header(class: "article-header", {
                html.h1(title)
                if subtitle != none {
                  html.p(class: "article-subtitle", subtitle)
                }

                if has-props {
                  html.elem("dl", attrs: (class: "post-props"), {
                    if eff-author != none {
                      html.elem("dt")[author]
                      html.elem("dd", eff-author)
                    }
                    if monograph != none {
                      html.elem("dt")[monograph]
                      html.elem("dd", monograph)
                    }
                    if created-str != none {
                      html.elem("dt")[created]
                      html.elem("dd", created-str)
                    }
                    if modified-str != none {
                      html.elem("dt")[modified]
                      html.elem("dd", modified-str)
                    }
                    if show-wordcount {
                      html.elem("dt")[words]
                      html.elem("dd", context str(query-body-words(base-words)))
                      html.elem("dt")[reading]
                      html.elem("dd", context {
                        (
                          str(estimate-reading-minutes(
                            query-body-words(base-words),
                            wpm: wpm,
                          ))
                            + " min"
                        )
                      })
                    }
                    if tags.len() > 0 {
                      html.elem("dt")[tags]
                      html.elem("dd", {
                        for t in tags {
                          html.span(class: "prop-tag", "#" + str(t))
                        }
                      })
                    }
                  })
                }
              })

              [#metadata(merged-theme) <typica-post-theme>]
              [#metadata(none) <typica-body-start>]
              body
              [#metadata(none) <typica-body-end>]
            },
          )
        },
      )
    } else {
      let eff-page-width = if page-width == auto {
        merged-theme.page-width
      } else { page-width }
      let eff-margin = if margin == auto { merged-theme.margin } else { margin }

      set page(
        width: eff-page-width,
        height: auto,
        margin: eff-margin,
        fill: merged-theme.paper-light,
      )
      show: zebraw-init
      show: checklist.with(
        marker-map: (
          " ": move(
            dy: -0.08em,
            box(
              baseline: bottom,
              circle(
                radius: 0.22em,
                stroke: 0.65pt + merged-theme.muted-light,
                fill: none,
              ),
            ),
          ),
          "x": move(
            dy: -0.08em,
            box(
              baseline: bottom,
              circle(
                radius: 0.22em,
                stroke: 0.65pt + merged-theme.text-light,
                fill: merged-theme.text-light,
              ),
            ),
          ),
        ),
      )
      show: with-smart-refs.with(
        ink: merged-theme.text-light,
        muted: merged-theme.muted-light,
      )
      show: style-paged-article.with(
        merged-theme,
        numbered-headings: numbered-headings,
      )

      block(width: 100%, below: 1.65em, {
        text(
          size: 2.0em,
          weight: "semibold",
          fill: merged-theme.text-light,
          title,
        )
        if subtitle != none {
          v(0.36em)
          text(size: 1.12em, fill: merged-theme.muted-light, emph(subtitle))
        }

        if has-props {
          v(0.75em)
          let prop-cells = ()
          if eff-author != none {
            prop-cells.push(text(fill: merged-theme.muted-light)[author])
            prop-cells.push(text(fill: merged-theme.text-light, eff-author))
          }
          if monograph != none {
            prop-cells.push(text(fill: merged-theme.muted-light)[monograph])
            prop-cells.push(text(fill: merged-theme.text-light, monograph))
          }
          if created-str != none {
            prop-cells.push(text(fill: merged-theme.muted-light)[created])
            prop-cells.push(text(fill: merged-theme.text-light, created-str))
          }
          if modified-str != none {
            prop-cells.push(text(fill: merged-theme.muted-light)[modified])
            prop-cells.push(text(fill: merged-theme.text-light, modified-str))
          }
          if show-wordcount {
            prop-cells.push(text(fill: merged-theme.muted-light)[words])
            prop-cells.push(text(fill: merged-theme.text-light, context str(
              query-body-words(base-words),
            )))
            prop-cells.push(text(fill: merged-theme.muted-light)[reading])
            prop-cells.push(text(fill: merged-theme.text-light, context {
              (
                str(estimate-reading-minutes(
                  query-body-words(base-words),
                  wpm: wpm,
                ))
                  + " min"
              )
            }))
          }
          if tags.len() > 0 {
            prop-cells.push(text(fill: merged-theme.muted-light)[tags])
            prop-cells.push(text(
              fill: merged-theme.muted-light,
              tags.map(t => "#" + str(t)).join("  "),
            ))
          }

          block(
            width: 100%,
            stroke: (
              top: 0.55pt + merged-theme.border-light,
              bottom: 0.55pt + merged-theme.border-light,
            ),
            inset: (y: 0.5em),
            {
              set text(font: merged-theme.mono-fonts, size: 0.76em)
              grid(
                columns: (5.8em, 1fr),
                row-gutter: 0.38em,
                column-gutter: 0.9em,
                align: (left + horizon, left + horizon),
                ..prop-cells,
              )
            },
          )
        }
      })

      [#metadata(merged-theme) <typica-post-theme>]
      [#metadata(none) <typica-body-start>]
      body
      [#metadata(none) <typica-body-end>]

      sidenote-bottom-guard()
    }
  }
}
