// Plain-text conversion, prose word counting, `<typica-word-hint>` tracking,
// and reading-time estimation.

#let _space-func = [ ].func()

/// Convert arbitrary Typst content (including `raw` and `math.equation`) or primitive value to plain `str`.
#let to-plain-text(it) = {
  if it == none {
    ""
  } else if type(it) == str {
    it
  } else if type(it) != content {
    str(it)
  } else if it == [ ] or it.func() == _space-func {
    " "
  } else if it.func() == parbreak or it.func() == linebreak {
    "\n"
  } else if it.has("text") {
    if type(it.text) == str { it.text } else { to-plain-text(it.text) }
  } else if it.has("children") {
    if it.children.len() == 0 { "" } else {
      it.children.map(to-plain-text).join("")
    }
  } else if it.has("body") {
    to-plain-text(it.body)
  } else if it.has("child") {
    to-plain-text(it.child)
  } else if it.has("base") {
    let s = to-plain-text(it.base)
    for k in ("tl", "bl") {
      if it.has(k) and it.at(k) != none { s = to-plain-text(it.at(k)) + s }
    }
    if it.has("accent") and it.accent != none { s += to-plain-text(it.accent) }
    if it.has("b") and it.b != none { s += "_" + to-plain-text(it.b) }
    if it.has("t") and it.t != none { s += "^" + to-plain-text(it.t) }
    for k in ("br", "tr") {
      if it.has(k) and it.at(k) != none { s += to-plain-text(it.at(k)) }
    }
    s
  } else if it.has("num") and it.has("denom") {
    to-plain-text(it.num) + "/" + to-plain-text(it.denom)
  } else if it.has("radicand") {
    let idx = if it.has("index") and it.index != none {
      to-plain-text(it.index)
    } else { "" }
    idx + "√(" + to-plain-text(it.radicand) + ")"
  } else if it.func() == math.primes and it.has("count") {
    "'" * it.count
  } else {
    ""
  }
}

/// Extract prose words from Typst content (skipping math equations and footnotes,
/// since footnotes are routed into `sidenote` which emits its own `<typica-word-hint>`).
#let _to-word-text(it) = {
  if it == none {
    " "
  } else if type(it) == str {
    it
  } else if type(it) != content {
    " "
  } else {
    let fn = it.func()
    if fn == math.equation or fn == footnote {
      " "
    } else if it.has("text") and type(it.text) == str {
      if fn == raw and it.at("block", default: false) {
        " " + it.text + " "
      } else {
        it.text
      }
    } else if fn == parbreak or fn == linebreak or it == [ ] {
      " "
    } else if fn == table or fn == grid {
      " " + it.children.map(ch => " " + _to-word-text(ch) + " ").join(" ") + " "
    } else if it.has("children") {
      it.children.map(_to-word-text).join()
    } else if it.has("body") {
      let sep = if fn in (heading, list.item, enum.item, par, block) {
        " "
      } else { "" }
      sep + _to-word-text(it.body) + sep
    } else if it.has("child") {
      _to-word-text(it.child)
    } else {
      " "
    }
  }
}

/// Count prose words in arbitrary Typst content.
#let count-words(body) = {
  _to-word-text(body)
    .matches(regex("[A-Za-z0-9]+(?:[-'\\u{2019}][A-Za-z0-9]+)*"))
    .len()
}

/// Emit a zero-footprint `<typica-word-hint>` marker from inside `context`-wrapped
/// components (`sbox`, `proof`, `sidenote`, `zebraw`, etc.) so `post` computes
/// full-article word counts without double-counting nested components.
#let word-hint(..parts) = [#metadata(parts
  .pos()
  .fold(0, (acc, p) => acc + count-words(p)))<typica-word-hint>]

/// Estimate reading time in minutes from word count (default 200 wpm).
#let estimate-reading-minutes(words, wpm: 200) = {
  calc.max(1, calc.ceil(words / wpm))
}

/// Sum `base-words` with all `<typica-word-hint>` markers emitted inside the
/// article body following `here()` (must be called inside `context`).
#let query-body-words(base-words) = {
  let starts = query(selector(<typica-body-start>).after(here()))
  let ends = query(selector(<typica-body-end>).after(here()))
  let extra = if starts.len() > 0 and ends.len() > 0 {
    query(
      selector(<typica-word-hint>)
        .after(starts.first().location())
        .before(ends.first().location()),
    ).fold(0, (acc, m) => acc + m.value)
  } else {
    0
  }
  base-words + extra
}
