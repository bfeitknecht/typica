// Monochrome `oklch` blog & math components inspired by `spicky`, built on top of
// `@preview/showybox:2.0.4`, `@preview/tablem:0.3.0`, `@preview/cheq:0.4.0`,
// and `@preview/zebraw:0.6.3` (without importing `spicky` itself).

#import "@preview/cheq:0.4.0": checklist
#import "@preview/showybox:2.0.4": showybox
#import "@preview/tablem:0.3.0": (
  tablem as _tablem, three-line-table as _three-line-table,
)
#import "@preview/zebraw:0.6.3": zebraw as _zebraw, zebraw-init, zebraw-themes
#import "refs.typ": resolve-abs-length
#import "theme.typ": active-theme
#import "words.typ": to-plain-text, word-hint

/// Markdown-like pipe table (`@preview/tablem:0.3.0`).
/// -> function
#let tablem = _tablem

/// Classic academic three-line table (`@preview/tablem:0.3.0`).
/// -> function
#let three-line-table = _three-line-table

/// Inner crosshair grid table built on `tablem` (`left` & `top` hairlines between cells).
/// -> content
#let grid-table(
  /// Markdown-style pipe table content block.
  /// -> content
  body,
  /// Additional arguments forwarded to `tablem`.
  /// -> any
  ..rest,
) = context {
  let t = active-theme()
  let inner = _tablem(
    render: (columns: auto, ..args) => table(
      columns: columns,
      stroke: (x, y) => (
        left: if x > 0 { 0.5pt + t.muted-light } else { none },
        top: if y > 0 { 0.5pt + t.muted-light } else { none },
        right: none,
        bottom: none,
      ),
      align: center + horizon,
      ..args,
    ),
    ..rest,
    body,
  )
  if target() == "html" {
    html.elem("div", attrs: (class: "typica-grid-table"), inner)
  } else {
    inner
  }
}

/// Monochrome-framed code block wrapper around `@preview/zebraw:0.6.3` with
/// native syntax highlighting, line numbers, line highlights, and HTML copy button.
/// -> content
#let zebraw(
  /// Code block and options forwarded to `@preview/zebraw`.
  /// -> any
  ..args,
  /// Highlighted line background (`auto` uses `theme.surface-2-light`).
  /// -> auto | color
  highlight-color: auto,
  /// Code block background (`auto` uses `theme.surface-1-light`).
  /// -> auto | color
  background-color: auto,
  /// Line-comment annotation fill (`auto` uses `theme.surface-2-light`).
  /// -> auto | color
  comment-color: auto,
  /// Language badge fill (`auto` uses `theme.surface-2-light`).
  /// -> auto | color
  lang-color: auto,
) = context {
  let t = active-theme()
  word-hint(..args.pos())
  _zebraw(
    highlight-color: if highlight-color == auto { t.surface-2-light } else {
      highlight-color
    },
    background-color: if background-color == auto { t.surface-1-light } else {
      background-color
    },
    comment-color: if comment-color == auto { t.surface-2-light } else {
      comment-color
    },
    lang-color: if lang-color == auto { t.surface-2-light } else { lang-color },
    ..args,
  )
}

/// Alias for `zebraw`.
/// -> function
#let codeblock = zebraw

#let _normalize-box-title(t) = {
  if t == none or t == [] {
    none
  } else if type(t) == content and t.func() == heading {
    t.body
  } else {
    t
  }
}

#let _sbox-paged-fill(variant, theme-cfg) = {
  if variant in ("definition", "theorem", "lemma", "proposition") {
    theme-cfg.surface-2-light
  } else if variant == "example" {
    theme-cfg.surface-1-light
  } else {
    theme-cfg.paper-light
  }
}

#let _sbox-html-head(kind, has-title, clean-title) = {
  if kind != none or has-title {
    html.div(class: "typica-sbox-head", {
      if kind != none { html.span(class: "typica-sbox-kind", kind + ".") }
      if has-title { html.span(class: "typica-sbox-title", clean-title) }
    })
  }
}

/// Multi-section monochrome environment box with uppercase sans-serif `kind` label.
/// -> content
#let sbox(
  /// Box title (`none` or `[]` omits the underlined title).
  /// -> content | str | none
  title,
  /// One or more body content blocks separated by dotted hairline rules.
  /// -> content
  ..sections,
  /// Visual surface variant (`"definition"`, `"theorem"`, `"example"`, `"recipe"`).
  /// -> str
  variant: "recipe",
  /// Uppercase sans-serif category label (e.g. `"Definition"`, `"Theorem"`).
  /// -> str | none
  kind: none,
) = context {
  let t = active-theme()
  let clean-title = _normalize-box-title(title)
  let has-title = (
    clean-title != none and to-plain-text(clean-title).trim().len() > 0
  )
  let parts = sections.pos()
  word-hint(kind, clean-title, ..parts)

  if target() == "html" {
    html.elem(
      "aside",
      attrs: (class: "typica-sbox", "data-variant": variant),
      {
        if parts.len() == 0 {
          if kind != none or has-title {
            html.div(class: "typica-sbox-part", _sbox-html-head(
              kind,
              has-title,
              clean-title,
            ))
          }
        } else {
          for (i, part) in parts.enumerate() {
            html.div(class: "typica-sbox-part", {
              if i == 0 { _sbox-html-head(kind, has-title, clean-title) }
              part
            })
          }
        }
      },
    )
  } else {
    let head-line = if kind != none or has-title {
      block(below: 0.45em, {
        if kind != none {
          text(
            font: t.sans-fonts,
            size: 0.78em,
            weight: "bold",
            tracking: 0.05em,
            fill: t.text-light,
            upper(kind) + ".",
          )
          if has-title { h(0.45em) }
        }
        if has-title {
          underline(
            stroke: 0.55pt + t.text-light,
            offset: 2pt,
            text(weight: "semibold", fill: t.text-light, clean-title),
          )
        }
      })
    } else {
      none
    }

    let sbox-parts = if parts.len() == 0 {
      if head-line != none { (head-line,) } else { ([],) }
    } else {
      parts
        .enumerate()
        .map(((i, part)) => {
          if i == 0 and head-line != none {
            head-line + part
          } else {
            part
          }
        })
    }

    showybox(
      frame: (
        border-color: t.frame-light,
        body-color: _sbox-paged-fill(variant, t),
        thickness: 0.65pt,
        radius: 2pt,
        inset: (x: 0.88em, y: 0.72em),
      ),
      body-style: (
        color: t.text-light,
      ),
      sep: (
        thickness: 0.5pt,
        dash: "dotted",
        gutter: 0.65em,
      ),
      above: 1.15em,
      below: 1.15em,
      ..sbox-parts,
    )
  }
}

/// Mathematical definition environment (`DEFINITION.`).
///
/// ```example
/// #definition[Pointed CPO][
///   An $omega$-CPO $(D, subset.eq.sq)$ with least element $bot in D$.
/// ]
/// ```
/// -> content
#let definition(
  /// Definition title.
  /// -> content | str | none
  title,
  /// One or more body sections.
  /// -> content
  ..sections,
) = sbox(title, ..sections.pos(), variant: "definition", kind: "Definition")

/// Theorem environment (`THEOREM.`).
///
/// ```example
/// #theorem[Kleene Fixed Point][
///   Every Scott-continuous map $F : D -> D$ has $"lfp"(F) = union.sq.big_(n >= 0) F^n (bot)$.
/// ]
/// ```
/// -> content
#let theorem(
  /// Theorem title.
  /// -> content | str | none
  title,
  /// One or more body sections.
  /// -> content
  ..sections,
) = sbox(title, ..sections.pos(), variant: "theorem", kind: "Theorem")

/// Lemma environment (`LEMMA.`).
/// -> content
#let lemma(title, ..sections) = sbox(
  title,
  ..sections.pos(),
  variant: "lemma",
  kind: "Lemma",
)

/// Proposition environment (`PROPOSITION.`).
/// -> content
#let proposition(title, ..sections) = sbox(
  title,
  ..sections.pos(),
  variant: "proposition",
  kind: "Proposition",
)

/// Example environment (`EXAMPLE.`).
/// -> content
#let example(title, ..sections) = sbox(
  title,
  ..sections.pos(),
  variant: "example",
  kind: "Example",
)

/// Recipe / procedure environment (`RECIPE.`).
/// -> content
#let recipe(title, ..sections) = sbox(
  title,
  ..sections.pos(),
  variant: "recipe",
  kind: "Recipe",
)

/// Remark environment (`REMARK.`).
/// -> content
#let remark(title, ..sections) = sbox(
  title,
  ..sections.pos(),
  variant: "recipe",
  kind: "Remark",
)

/// Proof block with subtle left rule and flush-right hollow Halmos square (`sym.square.stroked`).
///
/// ```example
/// #proof[
///   By induction on $n$, $F^n (bot) subset.eq.sq e$ for every pre-fixed point $e$.
/// ]
/// ```
/// -> content
#let proof(
  /// Uppercase sans-serif lead-in label (e.g. `[Proof]` or `[Proof sketch]`).
  /// -> content | str
  title: [Proof],
  /// Proof body.
  /// -> content
  body,
) = context {
  let t = active-theme()
  word-hint(title, body)
  if target() == "html" {
    html.elem("div", attrs: (class: "typica-proof"), {
      html.div(class: "typica-proof-head", title + [.])
      body
      html.div(class: "typica-qed-row", html.span(class: "typica-qed", []))
    })
  } else {
    block(
      width: 100%,
      stroke: (left: 1.2pt + t.border-light),
      inset: (left: 0.9em, y: 0.15em),
      above: 1em,
      below: 1.15em,
      {
        block(
          below: 0.48em,
          text(
            font: t.sans-fonts,
            size: 0.78em,
            weight: "bold",
            tracking: 0.05em,
            fill: t.text-light,
            upper(to-plain-text(title)) + ".",
          ),
        )
        body
        h(1fr) + sym.square.stroked
      },
    )
  }
}

#let _callout-labels = (
  note: "Note",
  tip: "Tip",
  warning: "Warning",
  important: "Important",
)

/// Monochrome left-bordered callout (`note`, `tip`, `warning`, `important`).
/// -> content
#let callout(
  /// Callout kind (`"note"`, `"tip"`, `"warning"`, `"important"`).
  /// -> str
  kind: "note",
  /// Custom heading (`auto` uses `kind`, `none` omits heading).
  /// -> auto | content | str | none
  title: auto,
  /// Callout content.
  /// -> content
  body,
) = context {
  let t = active-theme()
  let heading-text = if title == auto {
    _callout-labels.at(kind, default: "Note")
  } else { title }
  word-hint(heading-text, body)

  if target() == "html" {
    html.elem(
      "aside",
      attrs: (class: "typica-callout", "data-kind": kind),
      {
        if heading-text != none {
          html.elem("div", attrs: (class: "typica-callout-title"), heading-text)
        }
        body
      },
    )
  } else {
    block(
      width: 100%,
      fill: t.surface-1-light,
      stroke: (left: 2.2pt + t.text-light),
      inset: (x: 0.95em, y: 0.72em),
      radius: (right: 2.5pt),
      above: 1.1em,
      below: 1.1em,
      {
        if heading-text != none {
          block(
            below: 0.4em,
            text(
              font: t.sans-fonts,
              size: 0.78em,
              weight: "bold",
              tracking: 0.05em,
              fill: t.text-light,
              upper(to-plain-text(heading-text)),
            ),
          )
        }
        body
      },
    )
  }
}

#let note-box = callout.with(kind: "note")
#let tip-box = callout.with(kind: "tip")
#let warning-box = callout.with(kind: "warning")
#let important-box = callout.with(kind: "important")

/// Section-opening italic epigraph with optional right-aligned attribution.
///
/// ```example
/// #epigraph(source: [Edsger W. Dijkstra, EWD249])[
///   Simplicity is prerequisite for reliability.
/// ]
/// ```
/// -> content
#let epigraph(
  /// Optional attribution rendered flush-right in `Commit Mono`.
  /// -> content | str | none
  source: none,
  /// Quotation body.
  /// -> content
  body,
) = context {
  let t = active-theme()
  word-hint(body, source)
  if target() == "html" {
    html.elem("div", attrs: (class: "typica-epigraph"), {
      html.elem("blockquote", body)
      if source != none {
        html.elem(
          "div",
          attrs: (class: "typica-epigraph-source"),
          "- " + source,
        )
      }
    })
  } else {
    block(
      width: 92%,
      stroke: (left: 1.2pt + t.border-light),
      inset: (left: 0.95em, y: 0.2em),
      above: 1.1em,
      below: 1.35em,
      {
        emph(body)
        if source != none {
          v(0.35em)
          align(right, text(
            font: t.mono-fonts,
            size: 0.8em,
            fill: t.muted-light,
            "- " + source,
          ))
        }
      },
    )
  }
}

/// Full-width container spanning both the prose column and the right sidenote margin.
/// Automatically clears any active right-margin sidenotes in both HTML (`clear: right`)
/// and paged mode (`@preview/marge` page state).
/// -> content
#let wide(
  /// Wide table, figure, or listing body.
  /// -> content
  body,
) = context {
  let t = active-theme()
  word-hint(body)
  if target() == "html" {
    html.elem("div", attrs: (class: "typica-wide"), body)
  } else {
    let pg = here().page()
    let cur-y = here().position().y
    let notes = state("marge:0.1.0/page-" + str(pg), ()).get()
    let top-clear = if notes.len() > 0 {
      let max-note-y = notes.fold(0pt, (acc, n) => calc.max(
        acc,
        n.position.y + n.height,
      ))
      let clearance = 1.35em.to-absolute()
      calc.max(0pt, max-note-y + clearance - cur-y)
    } else {
      0pt
    }
    let default-right = resolve-abs-length(t.margin.right, fallback: 7.4cm)
    let default-left = resolve-abs-length(t.margin.left, fallback: 2.2cm)
    let right-m = if (
      type(page.margin) == dictionary and "right" in page.margin
    ) {
      resolve-abs-length(page.margin.right, fallback: default-right)
    } else {
      default-right
    }
    let extra = calc.max(0pt, right-m - default-left)
    block(
      width: 100% + extra,
      inset: (top: top-clear),
      above: 1.2em,
      below: 1.2em,
      body,
    )
  }
}

/// Render arbitrary Typst graphics natively in paged previews and as inline `<svg>` in HTML
/// (automatically inverted in dark mode).
/// -> content
#let diagram(
  /// Optional figure caption.
  /// -> content | str | none
  caption: none,
  /// Typst drawing or diagram content.
  /// -> content
  body,
) = context {
  word-hint(caption)
  if target() == "html" {
    html.elem("figure", attrs: (class: "typica-diagram"), {
      html.frame(body)
      if caption != none {
        html.elem("figcaption", caption)
      }
    })
  } else if caption != none {
    figure(body, kind: image, caption: caption)
  } else {
    align(center, body)
  }
}

/// Monochrome keyboard shortcut badge (`#kbd("Ctrl+P")`).
///
/// ```example
/// Press #kbd("Ctrl+P") for archival two-column print output.
/// ```
/// -> content
#let kbd(
  /// Key label text.
  /// -> content | str
  key,
) = context {
  let t = active-theme()
  if target() == "html" {
    html.elem("kbd", key)
  } else {
    box(
      fill: t.surface-1-light,
      stroke: 0.6pt + t.frame-light,
      inset: (x: 0.34em, y: 0.13em),
      outset: (y: 0.12em),
      radius: 2pt,
      text(size: 0.82em, font: t.mono-fonts, raw(if type(key) == str {
        key
      } else { to-plain-text(key) })),
    )
  }
}

/// Minimalist horizontal rule (`<hr>` in HTML, hairline rule in paged previews).
/// -> content
#let hr = context {
  let t = active-theme()
  if target() == "html" {
    html.elem("hr")
  } else {
    v(0.65em)
    line(length: 100%, stroke: 0.55pt + t.border-light)
    v(0.65em)
  }
}

/// Horizontal `Commit Mono` link row separated by middle dots (`·`) for thin homepages.
/// -> content
#let links-row(
  /// Link elements (e.g. `link("https://example.org")[example.org]`, `[@rss[rss]]`).
  /// -> content
  ..items,
) = context {
  let t = active-theme()
  let entries = items.pos()
  if target() == "html" {
    html.elem("ul", attrs: (class: "links"), {
      for item in entries {
        html.elem("li", item)
      }
    })
  } else {
    block(above: 0.6em, below: 1.2em, {
      set text(font: t.mono-fonts, size: 0.8em, fill: t.muted-light)
      entries.join(" · ")
    })
  }
}
