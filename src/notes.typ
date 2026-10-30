// Dual-target perceptual `oklch` monochrome margin sidenotes and margin notes.

#import "@preview/marge:0.1.0": (
  container as marge-container, sidenote as marge-sidenote,
)
#import "theme.typ": active-theme
#import "words.typ": word-hint

#let typica-sn-counter = counter("typica/sidenote")
#let typica-html-id-counter = counter("typica/html-note-id")

// Reset per-post sidenote counter (outside `context` for single-pass stability).
#let reset-sidenotes() = {
  typica-sn-counter.update(0)
}

// Internal monochrome formatter for `marge` sidenotes in paged preview mode.
#let format-paged-note(num-content, source-loc, theme-cfg, body) = {
  set text(
    font: theme-cfg.serif-fonts,
    size: 0.85em,
    fill: theme-cfg.muted-light,
  )
  set par(leading: 0.48em, justify: false)
  if num-content != none {
    let badge = (
      link(
        source-loc,
        text(
          size: 0.92em,
          fill: theme-cfg.text-light,
          weight: "regular",
          super(num-content),
        ),
      )
        + h(0.24em)
    )
    par(
      hanging-indent: measure(badge).width,
      badge + body,
    )
  } else {
    par(body)
  }
}

/// Place a numbered (or unnumbered) note in the right margin (`@preview/marge` in paged
/// previews; `<span class="sidenote">` float on desktop HTML and `@media print`, collapsing
/// into a tap-to-expand numbered card on viewports `<= 1100px`).
/// -> content
#let sidenote(
  /// Vertical offset adjustment in paged mode.
  /// -> length | ratio | relative
  dy: 0pt,
  /// Minimum vertical separation between consecutive paged margin notes.
  /// -> length
  gap: 0.55em,
  /// Horizontal inset inside the right margin column in paged mode.
  /// -> length | dictionary
  padding: (left: 1.4em, right: 1.8cm),
  /// Display synchronized superscript numbers in prose and at the start of the margin note.
  /// -> bool
  numbered: true,
  /// Margin note content.
  /// -> content
  body,
) = {
  typica-html-id-counter.step()
  context {
    word-hint(body)
    if target() == "html" {
      let id-num = typica-html-id-counter.get().first()
      let clean-body = {
        show par: it => it.body + html.br()
        body
      }
      if numbered {
        let id = "sn-" + str(id-num)
        html.elem("label", attrs: (
          "for": id,
          class: "margin-toggle sidenote-number",
        ))[]
        html.elem("input", attrs: (
          type: "checkbox",
          id: id,
          class: "margin-toggle",
        ))
        html.elem("span", attrs: (class: "sidenote"), clean-body)
      } else {
        let id = "mn-" + str(id-num)
        html.elem("label", attrs: ("for": id, class: "margin-toggle"), "[+]")
        html.elem("input", attrs: (
          type: "checkbox",
          id: id,
          class: "margin-toggle",
        ))
        html.elem("span", attrs: (class: "marginnote"), clean-body)
      }
    } else {
      let t = active-theme()
      show link: set text(size: 0.92em, fill: t.text-light, weight: "regular")
      marge-sidenote(
        side: right,
        dy: dy,
        gap: gap,
        padding: padding,
        numbering: if numbered { "1" } else { none },
        counter: typica-sn-counter,
        format: it => {
          let num-str = if it.numbering != none {
            it.counter.display(it.numbering)
          } else {
            none
          }
          set text(size: 1em / 0.85)
          format-paged-note(num-str, it.source, t, body)
        },
        body,
      )
    }
  }
}

/// Place an unnumbered margin note alongside the current paragraph (`[+] ` toggle on `<= 1100px`).
/// -> content
#let marginnote(
  /// Vertical offset adjustment in paged mode.
  /// -> length | ratio | relative
  dy: 0pt,
  /// Minimum vertical separation between consecutive paged margin notes.
  /// -> length
  gap: 0.55em,
  /// Margin note content.
  /// -> content
  body,
) = sidenote(
  dy: dy,
  gap: gap,
  numbered: false,
  body,
)

/// Short alias for `sidenote`.
/// -> function
#let sn = sidenote

/// Short alias for `marginnote`.
/// -> function
#let mn = marginnote

// Guard placed at the bottom of an `auto`-height paged preview so trailing
// margin notes expand the page height cleanly without clipping.
#let sidenote-bottom-guard() = context {
  if target() == "paged" and page.height == auto {
    let pg = here().page()
    let end-y = here().position().y
    let notes = state("marge:0.1.0/page-" + str(pg), ()).final()
    let max-y = notes.fold(end-y, (acc, n) => calc.max(
      acc,
      n.position.y + n.height,
    ))
    if max-y > end-y {
      v(max-y - end-y + 0.5em)
    }
  }
}

#let container = marge-container
