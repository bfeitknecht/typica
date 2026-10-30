// Path manipulation, date formatting, and universal cross-bundle `<label>` / `@ref` resolution.

#import "theme.typ": active-theme
#import "words.typ": to-plain-text

/// Safely resolve a `length` or `relative` length to an absolute `length`.
#let resolve-abs-length(val, fallback: 0pt) = {
  if val == auto or val == none {
    fallback
  } else if type(val) == length {
    val.to-absolute()
  } else if type(val) == relative {
    val.length.to-absolute()
  } else {
    fallback
  }
}

/// Convert a string or content into a URL-safe kebab-case slug.
#let slugify(input) = {
  lower(to-plain-text(input)).replace(regex("[^a-z0-9]+"), "-").trim("-")
}

/// Humanize a kebab-case slug or label name for fallback display.
#let humanize-slug(s) = {
  str(s).replace("-", " ").replace("_", " ")
}

/// Join path segments with single `/` separators and no leading slash.
#let join-path(..parts) = {
  parts.pos().map(p => str(p).trim("/")).filter(p => p.len() > 0).join("/")
}

/// Canonical bundle HTML path for a post (`posts/<slug>/index.html` by default).
#let post-html-path(slug, posts-dir: "posts") = {
  join-path(posts-dir, slug, "index.html")
}

/// Return the parent directory of a bundle document path (e.g. `"posts/gol"`).
#let parent-dir(doc-path) = {
  if doc-path == none {
    return ""
  }
  let parts = doc-path.trim("/").split("/")
  if parts.len() <= 1 {
    ""
  } else {
    parts.slice(0, parts.len() - 1).join("/")
  }
}

/// Derive a post slug from its bundle document path (e.g. `"posts/foo/index.html"` -> `"foo"`).
#let slug-from-path(doc-path) = {
  if doc-path == none {
    return none
  }
  let parts = doc-path.trim("/").split("/")
  let last = parts.last()
  if last == "index.html" and parts.len() >= 2 {
    parts.at(parts.len() - 2)
  } else {
    last.trim(".html", at: end)
  }
}

/// Compute relative root prefix (`""`, `"../"`, `"../../"`) for a bundle path.
#let rel-root(doc-path) = {
  if doc-path == none {
    return ""
  }
  let parts = doc-path.trim("/").split("/")
  if parts.len() <= 1 {
    ""
  } else {
    "../" * (parts.len() - 1)
  }
}

/// Extract domain authority from an HTTP(S) URL (e.g. `"https://blog.example.org/foo"` -> `"blog.example.org"`).
#let url-authority(url) = {
  let clean = str(url).replace(regex("^https?://"), "")
  clean.split("/").first().split(":").first()
}

/// Format a `datetime` or string into ISO `YYYY-MM-DD`.
#let format-date(d, fmt: "[year]-[month]-[day]") = {
  if d == none {
    none
  } else if type(d) == datetime {
    d.display(fmt)
  } else {
    to-plain-text(d)
  }
}

/// Sort key for dates (ascending ISO timestamp; reverse for newest-first).
#let date-sort-key(d) = {
  if type(d) == datetime {
    let norm = if d.hour() == none {
      datetime(
        year: d.year(),
        month: d.month(),
        day: d.day(),
        hour: 0,
        minute: 0,
        second: 0,
      )
    } else {
      d
    }
    norm.display("[year]-[month]-[day]T[hour]:[minute]:[second]")
  } else if d != none {
    to-plain-text(d)
  } else {
    "0000-00-00T00:00:00"
  }
}

/// Find the enclosing `document` element in bundle mode for a `<typica-post-meta>` location.
#let find-post-doc(meta-loc) = {
  for d in query(document) {
    let hits = query(selector(<typica-post-meta>).within(d.location()))
    if hits.any(m => m.location() == meta-loc) {
      return d
    }
  }
  none
}

/// Resolve a `<label>` across the bundle, preferring emitted `document` / `asset` / `heading`
/// targets over mount-marker `metadata` nodes, while falling back to mounted-post
/// `metadata` in paged preview mode so `@slug` still displays the post's real title.
#let resolve-bundle-label(lbl) = {
  let all = query(lbl)
  let non-meta = all.filter(el => el.func() != metadata)
  if non-meta.len() > 0 {
    return non-meta.first()
  }
  let mount-meta = all.filter(el => (
    el.func() == metadata
      and type(el.value) == dictionary
      and (
        el.value.at("typica-mounted-post", default: false)
          or el.value.at("typica-paged-ref", default: false)
      )
  ))
  if mount-meta.len() > 0 {
    return mount-meta.first()
  }
  none
}

/// Look up `<typica-post-meta>` inside a `document` element if present.
#let doc-post-meta(doc-el) = {
  let metas = query(selector(<typica-post-meta>).within(doc-el.location()))
  if metas.len() > 0 {
    metas.first().value
  } else {
    none
  }
}

/// Install universal cross-bundle `link` and `ref` (`@tag` / `<tag>`) rules
/// with graceful standalone single-post fallback.
#let with-smart-refs(
  ink: auto,
  muted: auto,
  body,
) = {
  show link: it => {
    if type(it.dest) == label {
      let el = resolve-bundle-label(it.dest)
      if el != none {
        link(el.location(), it.body)
      } else {
        it.body
      }
    } else {
      it
    }
  }

  show ref: it => {
    let el = resolve-bundle-label(it.target)
    let custom-text = if it.supplement != auto and it.supplement != none {
      it.supplement
    } else {
      none
    }

    if el != none {
      let func = el.func()
      let func-name = repr(func)
      if func-name == "document" or func-name == "asset" {
        let label-text = if custom-text != none {
          custom-text
        } else if func-name == "document" {
          let pm = doc-post-meta(el)
          if pm != none and pm.title != none {
            pm.title
          } else if el.title != none {
            el.title
          } else {
            humanize-slug(it.target)
          }
        } else {
          humanize-slug(it.target)
        }
        link(el.location(), label-text)
      } else if (
        func == metadata
          and type(el.value) == dictionary
          and (
            el.value.at("typica-mounted-post", default: false)
              or el.value.at("typica-paged-ref", default: false)
          )
      ) {
        let pm = el.value.at("meta", default: none)
        let label-text = if custom-text != none {
          custom-text
        } else if pm != none and pm.at("title", default: none) != none {
          pm.title
        } else {
          humanize-slug(it.target)
        }
        link(el.location(), label-text)
      } else if func == heading and el.numbering == none {
        let label-text = if custom-text != none {
          custom-text
        } else {
          el.body
        }
        link(el.location(), label-text)
      } else {
        it
      }
    } else if query(bibliography).len() == 0 {
      let fallback = if custom-text != none {
        custom-text
      } else {
        humanize-slug(it.target)
      }
      if target() == "html" {
        html.elem(
          "span",
          attrs: (class: "typica-unresolved-ref", title: "@" + str(it.target)),
          fallback,
        )
      } else {
        let t = active-theme()
        let eff-ink = if ink == auto { t.text-light } else { ink }
        let eff-muted = if muted == auto { t.muted-light } else { muted }
        underline(
          stroke: (paint: eff-muted, thickness: 0.6pt, dash: "dashed"),
          offset: 2pt,
          text(fill: eff-ink, fallback),
        )
      }
    } else {
      it
    }
  }

  body
}
