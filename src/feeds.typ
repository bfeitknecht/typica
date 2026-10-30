// Atom 1.0 and RSS 2.0 syndication feed builders backed by `@preview/exemel`.

// TODO: Remove `vendor/exemel` once upstream merges the RSS 2.0 PR and publishes
// `@preview/exemel:0.2.0` on Typst Universe.
#import "@preview/exemel:0.2.0": (
  atom-author, atom-encode, atom-post, atom-site-id, rss-encode, rss-post,
)
#import "refs.typ": url-authority

#let _fallback-epoch = datetime(
  year: 2026,
  month: 1,
  day: 1,
  hour: 0,
  minute: 0,
  second: 0,
)

#let _post-summary(p) = {
  if p.summary != none {
    p.summary
  } else if p.subtitle != none {
    p.subtitle
  } else {
    none
  }
}

/// Generate an Atom 1.0 XML feed string via `@preview/exemel` (`atom-encode`).
/// -> str
#let build-atom-feed(
  /// Feed title.
  /// -> content | str
  site-title: [Blog],
  /// Optional Atom `<subtitle>`.
  /// -> content | str | none
  site-subtitle: none,
  /// Canonical site origin URL.
  /// -> str
  site-url: "https://example.com",
  /// Default feed author name.
  /// -> content | str | none
  author: none,
  /// Relative path to the Atom feed (`atom.xml`).
  /// -> str
  atom-path: "atom.xml",
  /// Post records returned by `query-all-posts()`.
  /// -> array
  posts: (),
) = {
  let clean-url = site-url.trim("/", at: end)
  let authority = url-authority(clean-url)
  let feed-authors = if author != none {
    (atom-author(author, uri: clean-url + "/"),)
  } else {
    ()
  }

  let entries = posts.map(p => {
    let pub-dt = p.created
    let mod-dt = if p.modified != none {
      p.modified
    } else if pub-dt != none {
      pub-dt
    } else {
      _fallback-epoch
    }
    let id-dt = if pub-dt != none { pub-dt } else { mod-dt }
    let post-url = clean-url + "/" + p.html-path.trim("/", at: start)
    let entry-authors = if p.author != none and p.author != author {
      (atom-author(p.author),)
    } else {
      ()
    }
    atom-post(
      p.title,
      link: post-url,
      id: atom-site-id(
        authority: authority,
        time: id-dt,
        identifier: p.slug,
      ),
      updated: mod-dt,
      published: pub-dt,
      summary: _post-summary(p),
      authors: entry-authors,
      categories: p.tags,
    )
  })

  atom-encode(
    title: site-title,
    subtitle: site-subtitle,
    site-link: clean-url + "/",
    feed-link: clean-url + "/" + atom-path.trim("/", at: start),
    id: atom-site-id(
      authority: authority,
      time: _fallback-epoch,
      identifier: "feed",
    ),
    updated: if entries.len() > 0 { auto } else { _fallback-epoch },
    authors: feed-authors,
    posts: entries,
  )
}

/// Generate an RSS 2.0 XML feed string via `@preview/exemel` (`rss-encode`).
/// -> str
#let build-rss-feed(
  /// Channel `<title>`.
  /// -> content | str
  site-title: [Blog],
  /// Channel `<description>` (falls back to `site-title` when `none`).
  /// -> content | str | none
  site-subtitle: none,
  /// Canonical site origin URL.
  /// -> str
  site-url: "https://example.com",
  /// Relative path to the RSS feed (`rss.xml`) for `atom:link rel="self"`.
  /// -> str
  rss-path: "rss.xml",
  /// Post records returned by `query-all-posts()`.
  /// -> array
  posts: (),
) = {
  let clean-url = site-url.trim("/", at: end)
  let items = posts.map(p => rss-post(
    p.title,
    link: clean-url + "/" + p.html-path.trim("/", at: start),
    published: p.created,
    summary: _post-summary(p),
    categories: p.tags,
  ))

  rss-encode(
    title: site-title,
    subtitle: site-subtitle,
    site-link: clean-url + "/",
    feed-link: clean-url + "/" + rss-path.trim("/", at: start),
    posts: items,
  )
}
