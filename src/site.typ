// Thin, unopinionated HTML-only static site bundler (`site`, `post-list`).
//
// Supports both flat post files (`posts/foo.typ`) and optional per-post directories
// (`posts/foo/index.typ` with co-located assets emitted alongside `posts/foo/index.html`).

#import "feeds.typ": build-atom-feed, build-rss-feed
#import "html.typ": render-html-shell, render-not-found-page
#import "post.typ": post, query-all-posts
#import "refs.typ": (
  join-path, parent-dir, post-html-path, resolve-bundle-label, slugify,
)
#import "theme.typ": (
  active-theme, build-stylesheet, resolve-theme, stylesheet-asset-path,
)

// Extract the first top-level (`depth == 1`) heading body from homepage `body`
// (ignoring mounted posts).
#let _extract-first-h1(c) = {
  if type(c) != content {
    return none
  }
  if (
    c.func() == metadata
      and type(c.value) == dictionary
      and c.value.at("typica-mounted-post", default: false)
  ) {
    return none
  }
  if c.func() == heading and c.at("depth", default: 1) == 1 {
    return c.body
  }
  if c.has("child") {
    let found = _extract-first-h1(c.child)
    if found != none { return found }
  }
  if c.has("body") and c.func() != heading {
    let found = _extract-first-h1(c.body)
    if found != none { return found }
  }
  if c.has("children") {
    for ch in c.children {
      let found = _extract-first-h1(ch)
      if found != none { return found }
    }
  }
  none
}

// Extract all mounted post metadata records synchronously from a content tree.
#let _extract-mounted-posts(c) = {
  if type(c) != content {
    return ()
  }
  if (
    c.func() == metadata
      and type(c.value) == dictionary
      and c.value.at("typica-mounted-post", default: false)
  ) {
    return ((el: c, val: c.value, lbl: c.at("label", default: none)),)
  }
  let out = ()
  if c.has("child") {
    out += _extract-mounted-posts(c.child)
  }
  if c.has("body") {
    out += _extract-mounted-posts(c.body)
  }
  if c.has("children") {
    for ch in c.children {
      out += _extract-mounted-posts(ch)
    }
  }
  out
}

// Replace mounted-post `metadata` markers inside homepage `body` with rendered
// homepage entry cards (without duplicating `<slug>`, which attaches to `document(...)`).
#let _replace-mounted-posts(c, render-fn) = {
  if type(c) != content {
    return c
  }
  if (
    c.func() == metadata
      and type(c.value) == dictionary
      and c.value.at("typica-mounted-post", default: false)
  ) {
    return render-fn((el: c, val: c.value, lbl: c.at("label", default: none)))
  }
  if c.func() == [].func() and c.has("children") {
    return c.children.map(ch => _replace-mounted-posts(ch, render-fn)).join()
  }
  c
}

// Shared entry renderer for both inline `#post(...)` mounts and `#post-list()`.
#let _render-entry-card(
  title: none,
  dest: none,
  created-str: none,
  summary: none,
  subtitle: none,
  show-summary: true,
  wrapper-tag: "div",
  theme-cfg: none,
) = {
  let desc = if summary != none { summary } else { subtitle }
  if target() == "html" {
    html.elem(wrapper-tag, attrs: (class: "entry"), {
      html.div(class: "entry-head", {
        html.h3(if dest != none { link(dest, title) } else { title })
        if created-str != none {
          html.span(class: "when", created-str)
        }
      })
      if show-summary and desc != none {
        html.p(class: "entry-summary", desc)
      }
    })
  } else {
    block(below: 0.65em, {
      strong(title)
      if created-str != none {
        h(1fr)
        text(font: theme-cfg.mono-fonts, size: 0.8em, created-str)
      }
    })
  }
}

/// Render a newest-first `<ul class="entries">` list of all non-draft, non-unlisted
/// posts in the active bundle using `query-all-posts()`.
/// -> content
#let post-list(
  /// Include each post's `summary` (or `subtitle` fallback) beneath its title row.
  /// -> bool
  show-summary: true,
) = context {
  let t = active-theme()
  let posts = query-all-posts()
  if target() == "html" {
    html.elem("ul", attrs: (class: "entries"), {
      for p in posts {
        _render-entry-card(
          title: p.title,
          dest: p.doc-loc,
          created-str: p.created-str,
          summary: p.summary,
          subtitle: p.subtitle,
          show-summary: show-summary,
          wrapper-tag: "li",
          theme-cfg: t,
        )
      }
    })
  } else {
    for p in posts {
      _render-entry-card(
        title: p.title,
        created-str: p.created-str,
        show-summary: show-summary,
        theme-cfg: t,
      )
    }
  }
}

// Normalize a mounted post record into `(slug, label, path, dir, assets, title, body)`.
#let _resolve-mount(rec, posts-dir: "posts") = {
  let v = rec.val
  let lbl = rec.lbl
  let slug = if v.slug != none {
    v.slug
  } else if lbl != none {
    str(lbl)
  } else {
    slugify(v.meta.title)
  }
  let doc-lbl = if lbl != none { lbl } else { label(slug) }
  let html-path = if v.path != none {
    v.path
  } else {
    post-html-path(slug, posts-dir: posts-dir)
  }
  (
    slug: slug,
    label: doc-lbl,
    path: html-path,
    dir: parent-dir(html-path),
    assets: v.meta.at("assets", default: ()),
    title: v.meta.title,
    meta: v.meta,
    body: v.body,
    orig: v,
  )
}

// Render a mounted post as a minimalist homepage entry right where `#post(...)` sits.
#let _render-mounted-entry(rec, posts-dir: "posts", show-summary: true) = {
  let m = _resolve-mount(rec, posts-dir: posts-dir)
  let pm = m.meta
  if pm.at("draft", default: false) or pm.at("unlisted", default: false) {
    return []
  }
  context {
    let t = active-theme()
    let target-el = if target() == "html" {
      resolve-bundle-label(m.label)
    } else { none }
    _render-entry-card(
      title: m.title,
      dest: if target-el != none { target-el.location() } else { none },
      created-str: pm.at("created-str", default: none),
      summary: pm.at("summary", default: none),
      subtitle: pm.at("subtitle", default: none),
      show-summary: show-summary,
      wrapper-tag: "div",
      theme-cfg: t,
    )
  }
}

// Emit a single bundle asset (with optional `<label>`).
#let _emit-asset(path, data, lbl: none) = {
  if lbl != none {
    [#asset(path, data)#lbl]
  } else {
    asset(path, data)
  }
}

/// Top-level site bundler (`#show: site.with(...)`).
///
/// Renders `site.typ`'s body as `index.html` (`<site>`), emits every mounted
/// `#post(include "posts/foo.typ") <foo>` (or `"posts/foo/index.typ"`) as
/// `<posts-dir>/foo/index.html` (`<foo>`) alongside any co-located post assets,
/// and generates `css/style.css` (`<stylesheet>`), `404.html`, `rss.xml` (`<rss>`),
/// and `atom.xml` (`<atom>`). Feed `<link rel="alternate">` discovery tags are
/// emitted exclusively on `index.html`.
/// -> content
#let site(
  /// Site title (`auto` infers from the first `= ...` heading in `body`, or pass
  /// any string / rich content such as `` `something` `` or `$sin(x)$` — rendered
  /// automatically as the homepage `<h1>` if `body` omits a top-level heading, and
  /// serialized to plain text for `<title>`, `404.html`, and RSS / Atom feeds).
  /// -> auto | content | str
  title: auto,
  /// Short site description for `<meta name="description">` and feed subtitles.
  /// -> content | str | none
  description: none,
  /// Canonical origin URL (without trailing slash) used to construct absolute feed links.
  /// -> str
  url: "https://example.com",
  /// Default author inherited by posts that omit `author` and emitted in Atom `<author>`.
  /// -> content | str | none
  author: none,
  /// Output directory prefix for emitted post pages (`posts/<slug>/index.html`).
  /// -> str
  posts-dir: "posts",
  /// Additional standalone HTML pages `(slug: "about", title: [About], body: [...])`.
  /// -> array
  pages: (),
  /// Site-wide static assets `(path: "robots.txt", data: bytes(...), label: none)`.
  /// -> array
  assets: (),
  /// Emit `404.html` styled with the active site palette and typography.
  /// -> bool
  not-found-page: true,
  /// Output bundle path for the RSS 2.0 feed, or `none` to disable RSS generation.
  /// -> str | none
  rss-path: "rss.xml",
  /// Output bundle path for the Atom 1.0 feed, or `none` to disable Atom generation.
  /// -> str | none
  atom-path: "atom.xml",
  /// Theme overrides merged onto `default-theme` across both HTML CSS and paged previews.
  /// -> dictionary
  theme: (:),
  /// Homepage markup (`= Heading`, `#links-row(...)`, and mounted `#post(...) <slug>` entries).
  /// -> content
  body,
) = {
  let theme-cfg = resolve-theme(theme)
  let h1-in-body = _extract-first-h1(body)
  let resolved-title = if title != auto {
    title
  } else if h1-in-body != none {
    h1-in-body
  } else {
    [Blog]
  }
  let emit-auto-h1 = h1-in-body == none and resolved-title != none

  let site-cfg = (
    title: resolved-title,
    description: description,
    url: url,
    author: author,
    posts-dir: posts-dir,
    theme: theme-cfg,
    rss-path: rss-path,
    atom-path: atom-path,
  )

  [#metadata(site-cfg) <typica-site-cfg>]

  let body-mounts = _extract-mounted-posts(body)
  let clean-home-body = _replace-mounted-posts(
    body,
    rec => _render-mounted-entry(rec, posts-dir: posts-dir),
  )

  context {
    let pre-els = query(selector(metadata).before(here())).filter(el => (
      type(el.value) == dictionary
        and el.value.at("typica-mounted-post", default: false)
    ))
    let pre-mounts = pre-els.map(el => (
      el: el,
      val: el.value,
      lbl: el.at("label", default: none),
    ))
    let all-mounts = (pre-mounts + body-mounts).map(rec => _resolve-mount(
      rec,
      posts-dir: posts-dir,
    ))

    if target() == "bundle" {
      [#asset(stylesheet-asset-path, bytes(
        build-stylesheet(theme: theme-cfg),
      )) <stylesheet>]

      for a in assets {
        _emit-asset(a.path, a.data, lbl: a.at("label", default: none))
      }

      [#document(
        "index.html",
        title: resolved-title,
        {
          context {
            render-html-shell(
              title: resolved-title,
              site-title: resolved-title,
              description: description,
              author: author,
              doc-path: "index.html",
              theme-cfg: theme-cfg,
              include-feeds: true,
              rss-path: rss-path,
              atom-path: atom-path,
              {
                show heading.where(level: 1): it => html.h1(it.body)
                show heading.where(level: 2): it => html.h2(it.body)
                show heading.where(level: 3): it => html.h3(it.body)
                if emit-auto-h1 {
                  html.h1(resolved-title)
                }
                clean-home-body
              },
            )
          }
        },
      ) <site>]

      if not-found-page {
        document(
          "404.html",
          title: [404],
          render-not-found-page(site-title: resolved-title),
        )
      }

      for m in all-mounts {
        [#document(m.path, title: m.title, m.body)#m.label]
        for pa in m.assets {
          _emit-asset(join-path(m.dir, pa.path), pa.data, lbl: pa.at(
            "label",
            default: none,
          ))
        }
      }

      for pg in pages {
        let slug = pg.slug
        let pg-title = pg.at("title", default: resolved-title)
        let pg-path = pg.at("path", default: join-path(slug, "index.html"))
        [#document(
            pg-path,
            title: pg-title,
            {
              context {
                render-html-shell(
                  title: pg-title,
                  site-title: resolved-title,
                  author: author,
                  doc-path: pg-path,
                  theme-cfg: theme-cfg,
                  include-feeds: false,
                  pg.body,
                )
              }
            },
          )#label(slug)]
      }
    } else if all-mounts.len() > 0 {
      all-mounts.first().body
      for m in all-mounts.slice(1) {
        if pre-els.all(el => el.at("label", default: none) != m.label) {
          [#metadata((typica-paged-ref: true, meta: m.orig.meta))#m.label]
        }
      }
    } else {
      if emit-auto-h1 {
        heading(level: 1, resolved-title)
      }
      body
    }
  }

  // Atom 1.0 (`<atom>`) and RSS 2.0 (`<rss>`) syndication feeds via `@preview/exemel`
  context {
    if target() == "bundle" {
      let all-posts = query-all-posts()
      if rss-path != none {
        let rss-xml = build-rss-feed(
          site-title: resolved-title,
          site-subtitle: description,
          site-url: url,
          rss-path: rss-path,
          posts: all-posts,
        )
        [#asset(rss-path, bytes(rss-xml)) <rss>]
      }
      if atom-path != none {
        let atom-xml = build-atom-feed(
          site-title: resolved-title,
          site-subtitle: description,
          site-url: url,
          author: author,
          atom-path: atom-path,
          posts: all-posts,
        )
        [#asset(atom-path, bytes(atom-xml)) <atom>]
      }
    }
  }
}
