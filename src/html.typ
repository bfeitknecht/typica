// Shared HTML5 document shell, 404 error page renderer, and clipboard handler.

#import "@preview/cheq:0.4.0": checklist
#import "@preview/zebraw:0.6.3": zebraw-init
#import "refs.typ": rel-root, with-smart-refs
#import "theme.typ": build-stylesheet, default-theme, stylesheet-href
#import "words.typ": to-plain-text

/// Minimal event-delegated copy-button handler for `zebraw` code listings.
#let clipboard-script = "document.addEventListener('click', (ev) => {
  const btn = ev.target.closest('.expressive-code .copy-button');
  if (!btn) return;
  const box = btn.closest('.expressive-code');
  if (!box) return;
  const lines = Array.from(box.querySelectorAll('.ec-line .code')).map(el => el.textContent);
  if (navigator.clipboard && lines.length) {
    navigator.clipboard.writeText(lines.join('\\n')).then(() => {
      btn.setAttribute('data-state', 'copied');
      setTimeout(() => btn.setAttribute('data-state', 'idle'), 1600);
    });
  }
});"

/// Minimal HTML5 document shell (`<html><head>...</head><body><main>...</main></body></html>`).
/// Feed `<link rel="alternate">` tags are emitted only when `include-feeds: true` (homepage).
#let render-html-shell(
  title: [Blog],
  site-title: none,
  description: none,
  author: none,
  doc-path: none,
  theme-cfg: default-theme,
  include-feeds: false,
  rss-path: "rss.xml",
  atom-path: "atom.xml",
  body,
) = {
  let in-bundle = doc-path != none
  let root-prefix = rel-root(doc-path)
  let title-str = to-plain-text(title)
  let site-str = if site-title != none { to-plain-text(site-title) } else {
    none
  }
  let page-title-str = if site-str != none and title-str != site-str {
    title-str + " - " + site-str
  } else {
    title-str
  }

  counter("zebraw-html-styles").step()
  counter("zebraw-html-clipboard").step()

  html.html(lang: "en", {
    html.head({
      html.meta(charset: "utf-8")
      html.meta(
        name: "viewport",
        content: "width=device-width, initial-scale=1",
      )
      if description != none {
        html.meta(name: "description", content: to-plain-text(description))
      }
      if author != none {
        html.meta(name: "author", content: to-plain-text(author))
      }
      html.title(page-title-str)
      if in-bundle {
        html.link(
          rel: "stylesheet",
          href: stylesheet-href(root-prefix: root-prefix),
        )
        if include-feeds {
          let label-base = if site-str != none { site-str } else { title-str }
          if rss-path != none {
            html.link(
              rel: "alternate",
              type: "application/rss+xml",
              title: label-base + " RSS",
              href: root-prefix + rss-path.trim("/"),
            )
          }
          if atom-path != none {
            html.link(
              rel: "alternate",
              type: "application/atom+xml",
              title: label-base + " Atom",
              href: root-prefix + atom-path.trim("/"),
            )
          }
        }
      } else {
        html.style(build-stylesheet(theme: theme-cfg))
      }
      html.script(clipboard-script)
    })

    html.body({
      show: zebraw-init
      show: checklist
      show: with-smart-refs.with(
        ink: theme-cfg.text-light,
        muted: theme-cfg.muted-light,
      )

      html.main(body)
    })
  })
}

/// Render a minimal root-relative `404.html` document (compatible with `static-web-server`
/// `SERVER_ERROR_PAGE_404=./404.html` served at arbitrary nested URL paths).
#let render-not-found-page(site-title: [Blog], home-text: "/..") = {
  html.html(lang: "en", {
    html.head({
      html.meta(charset: "utf-8")
      html.meta(
        name: "viewport",
        content: "width=device-width, initial-scale=1",
      )
      html.meta(name: "robots", content: "noindex")
      html.title("404 - " + to-plain-text(site-title))
      html.link(rel: "stylesheet", href: stylesheet-href(root-prefix: "/"))
    })
    html.body({
      html.main({
        html.elem("nav", attrs: (class: "back-home"), html.elem(
          "a",
          attrs: (href: "/"),
          home-text,
        ))
        html.h1("404")
        html.p(class: "lede", "No such page.")
      })
    })
  })
}
