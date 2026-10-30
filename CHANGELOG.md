# Changelog

All notable changes to `typica` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-28

### Added

- Thin HTML-only static site bundler (`site`, `post`, `post-list`, `post-asset`, `query-all-posts`) emitting `index.html`, `404.html`, `posts/<slug>/index.html`, co-located post assets, `css/style.css`, `rss.xml`, and `atom.xml` in a single `typst compile --features html,bundle` invocation.
- Support for both flat post files (`posts/<slug>.typ`) and optional per-post asset directories (`posts/<slug>/index.typ`).
- Perceptual monochrome `oklch` / `oklab` theme (`default-theme`, `resolve-theme`, `active-theme`, `build-stylesheet`) with automatic OS dark/light mode (`color-scheme: dark light` + `light-dark(...)`) and two-column `@media print` archival layout (`Ctrl+P`).
- Unified _STIX Two_ default typography (`STIX Two Text` prose & sidenotes + `STIX Two Math` native browser MathML equations), _Helvetica Neue_ environment labels, and _Commit Mono_ code & metadata — all overridable via `theme: (...)` across both HTML and paged targets.
- Obsidian-style post frontmatter (`author`, optional EWD-style `monograph`, `created`, `modified`, dynamic `words`, dynamic `reading`, and `#tag` labels).
- Mathematical & technical components: `definition`, `theorem`, `example`, `recipe`, `sbox`, `proof` (hollow QED), `grid-table`, `tablem`, right-margin `sidenote` / `note` (`<= 1100px` numbered CSS pop-ups), `zebraw` / `codeblock` syntax highlighting with copy buttons, `checklist` hollow/filled circle markers, `wide`, `diagram`, `epigraph`, `kbd`, and `links-row`.
- Universal cross-bundle `<label>` / `@ref` resolution (`@site`, `@<slug>`, `@rss`, `@atom`, and cross-post section headings) with graceful standalone fallback.
- Reference manual (`docs/manual.pdf`), dark/light showcase previews (`assets/`), and standalone `examples/`.
