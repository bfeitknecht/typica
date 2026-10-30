// Perceptual `oklch` monochrome theme tokens, configurable font stacks,
// layout geometry, and CSS stylesheet builder.

#let stylesheet-version = "18"
#let stylesheet-asset-path = "css/style.css"

#let _stix-cdn = "https://cdn.jsdelivr.net/gh/stipub/stixfonts@v2.13b171/fonts/static_otf_woff2/"
#let _commit-mono-cdn = "https://cdn.jsdelivr.net/fontsource/fonts/commit-mono@latest/"

#let _builtin-font-faces = (
  "STIX Two Text": (
    "@font-face {\n  font-family: \"STIX Two Text\";\n  src: local(\"STIX Two Text\"), local(\"STIXTwoText-Regular\"),\n       url(\""
      + _stix-cdn
      + "STIXTwoText-Regular.woff2\") format(\"woff2\");\n  font-weight: 400;\n  font-style: normal;\n  font-display: swap;\n}",
    "@font-face {\n  font-family: \"STIX Two Text\";\n  src: local(\"STIX Two Text Italic\"), local(\"STIXTwoText-Italic\"),\n       url(\""
      + _stix-cdn
      + "STIXTwoText-Italic.woff2\") format(\"woff2\");\n  font-weight: 400;\n  font-style: italic;\n  font-display: swap;\n}",
    "@font-face {\n  font-family: \"STIX Two Text\";\n  src: local(\"STIX Two Text SemiBold\"), local(\"STIXTwoText-SemiBold\"),\n       url(\""
      + _stix-cdn
      + "STIXTwoText-SemiBold.woff2\") format(\"woff2\");\n  font-weight: 600;\n  font-style: normal;\n  font-display: swap;\n}",
    "@font-face {\n  font-family: \"STIX Two Text\";\n  src: local(\"STIX Two Text SemiBold Italic\"), local(\"STIXTwoText-SemiBoldItalic\"),\n       url(\""
      + _stix-cdn
      + "STIXTwoText-SemiBoldItalic.woff2\") format(\"woff2\");\n  font-weight: 600;\n  font-style: italic;\n  font-display: swap;\n}",
    "@font-face {\n  font-family: \"STIX Two Text\";\n  src: local(\"STIX Two Text Bold\"), local(\"STIXTwoText-Bold\"),\n       url(\""
      + _stix-cdn
      + "STIXTwoText-Bold.woff2\") format(\"woff2\");\n  font-weight: 700;\n  font-style: normal;\n  font-display: swap;\n}",
    "@font-face {\n  font-family: \"STIX Two Text\";\n  src: local(\"STIX Two Text Bold Italic\"), local(\"STIXTwoText-BoldItalic\"),\n       url(\""
      + _stix-cdn
      + "STIXTwoText-BoldItalic.woff2\") format(\"woff2\");\n  font-weight: 700;\n  font-style: italic;\n  font-display: swap;\n}",
  ).join("\n\n"),
  "STIX Two Math": (
    "@font-face {\n  font-family: \"STIX Two Math\";\n  src: local(\"STIX Two Math\"), local(\"STIXTwoMath-Regular\"),\n       url(\""
      + _stix-cdn
      + "STIXTwoMath-Regular.woff2\") format(\"woff2\");\n  font-weight: 400;\n  font-style: normal;\n  font-display: swap;\n}"
  ),
  "Commit Mono": (
    "@font-face {\n  font-family: \"Commit Mono\";\n  src: local(\"Commit Mono\"), local(\"CommitMono\"), local(\"CommitMono-Regular\"),\n       url(\""
      + _commit-mono-cdn
      + "latin-400-normal.woff2\") format(\"woff2\");\n  font-weight: 400;\n  font-style: normal;\n  font-display: swap;\n}",
    "@font-face {\n  font-family: \"Commit Mono\";\n  src: local(\"Commit Mono Italic\"), local(\"CommitMono Italic\"), local(\"CommitMono-Italic\"),\n       url(\""
      + _commit-mono-cdn
      + "latin-400-italic.woff2\") format(\"woff2\");\n  font-weight: 400;\n  font-style: italic;\n  font-display: swap;\n}",
    "@font-face {\n  font-family: \"Commit Mono\";\n  src: local(\"Commit Mono Bold\"), local(\"CommitMono Bold\"), local(\"CommitMono-Bold\"),\n       url(\""
      + _commit-mono-cdn
      + "latin-700-normal.woff2\") format(\"woff2\");\n  font-weight: 700;\n  font-style: normal;\n  font-display: swap;\n}",
  ).join("\n\n"),
)

// Compute a relative or root-anchored `style.css` href with cache-busting query string.
#let stylesheet-href(root-prefix: "") = {
  root-prefix + stylesheet-asset-path + "?v=" + stylesheet-version
}

// Convert any Typst `color` into a perceptual CSS Color 4 `oklch(...)` string.
#let css-oklch(col) = {
  let (l, c, h, a) = oklch(col).components()
  let c-clean = if calc.abs(c) < 0.0005 { 0 } else { calc.round(c, digits: 4) }
  let h-clean = if c-clean == 0 { "0" } else {
    str(calc.round(h.deg(), digits: 2)) + "deg"
  }
  let l-str = str(calc.round(l / 1%, digits: 2)) + "%"
  if a < 100% {
    (
      "oklch("
        + l-str
        + " "
        + str(c-clean)
        + " "
        + h-clean
        + " / "
        + str(calc.round(a / 1%, digits: 2))
        + "%)"
    )
  } else {
    "oklch(" + l-str + " " + str(c-clean) + " " + h-clean + ")"
  }
}

// Normalize a font list (`str` or `array` of `str`) into an array of family names.
#let _font-list(fonts) = {
  if type(fonts) == str {
    (fonts,)
  } else if type(fonts) == array {
    fonts.map(str)
  } else {
    ()
  }
}

// Format a Typst font-family list into a CSS `font-family` value with generic fallback.
#let _css-font-stack(fonts, generic-tail) = {
  let quoted = _font-list(fonts).map(f => "\"" + f.replace("\"", "") + "\"")
  (quoted + generic-tail).join(", ")
}

/// Default perceptual `oklch(L, 0, 0deg)` monochrome palette, unified _STIX Two_ +
/// _Helvetica Neue_ + _Commit Mono_ font stacks, and paged preview geometry.
/// -> dictionary
#let default-theme = (
  paper-light: oklch(99%, 0, 0deg),
  text-light: oklch(18%, 0, 0deg),
  muted-light: oklch(52%, 0, 0deg),
  border-light: oklch(89%, 0, 0deg),
  frame-light: oklch(20%, 0, 0deg),
  surface-1-light: oklch(96.5%, 0, 0deg),
  surface-2-light: oklch(93.5%, 0, 0deg),
  paper-dark: oklch(18%, 0, 0deg),
  text-dark: oklch(93%, 0, 0deg),
  muted-dark: oklch(65%, 0, 0deg),
  border-dark: oklch(29%, 0, 0deg),
  frame-dark: oklch(84%, 0, 0deg),
  surface-1-dark: oklch(22%, 0, 0deg),
  surface-2-dark: oklch(26%, 0, 0deg),
  serif-fonts: (
    "STIX Two Text",
    "Libertinus Serif",
  ),
  math-fonts: (
    "STIX Two Math",
    "New Computer Modern Math",
  ),
  sans-fonts: (
    "Helvetica Neue",
    "Helvetica",
    "Arial",
    "DejaVu Sans",
  ),
  mono-fonts: (
    "Commit Mono",
    "CommitMono",
    "DejaVu Sans Mono",
  ),
  // `auto` emits built-in `@font-face` blocks for any default family present in the
  // stacks above; pass a custom CSS string (or `""` / `none`) when using custom web fonts.
  font-faces: auto,
  page-width: 22cm,
  margin: (
    left: 2.2cm,
    right: 7.4cm,
    top: 2.0cm,
    bottom: 2.2cm,
  ),
  font-size: 10.8pt,
)

/// Merge a user `theme` override dictionary onto `default-theme`.
/// -> dictionary
#let resolve-theme(
  /// Partial theme dictionary overriding any subset of `default-theme` keys.
  /// -> dictionary | none
  overrides,
) = {
  if overrides == none or overrides == (:) {
    default-theme
  } else {
    default-theme + overrides
  }
}

/// Resolve the active theme inside `context` (preferring any enclosing per-post
/// `<typica-post-theme>` override over site-wide `<typica-site-cfg>`).
/// -> dictionary
#let active-theme() = {
  let post-themes = query(selector(<typica-post-theme>).before(here()))
  if post-themes.len() > 0 {
    post-themes.last().value
  } else {
    let cfgs = query(<typica-site-cfg>)
    if cfgs.len() > 0 {
      cfgs.first().value.theme
    } else {
      default-theme
    }
  }
}

#let _resolve-font-faces(t) = {
  let ff = t.at("font-faces", default: auto)
  if ff == none {
    ""
  } else if ff != auto {
    str(ff)
  } else {
    let used = (
      _font-list(t.serif-fonts)
        + _font-list(t.math-fonts)
        + _font-list(t.sans-fonts)
        + _font-list(t.mono-fonts)
    )
    let blocks = ()
    for (fam, css-block) in _builtin-font-faces.pairs() {
      if fam in used {
        blocks.push(css-block)
      }
    }
    blocks.join("\n\n")
  }
}

/// Render `src/style.css` substituting all `oklch(...)` palette tokens, `--serif` / `--math` /
/// `--sans` / `--mono` font stacks, and `@font-face` declarations from `theme`.
/// -> str
#let build-stylesheet(
  /// Theme dictionary (`default-theme` or user overrides).
  /// -> dictionary
  theme: default-theme,
) = {
  let t = resolve-theme(theme)
  let token-map = (
    "__FONT_FACES__": _resolve-font-faces(t),
    "__FONT_SERIF__": _css-font-stack(t.serif-fonts, ("Georgia", "serif")),
    "__FONT_MATH__": _css-font-stack(t.math-fonts, ("math",)),
    "__FONT_SANS__": _css-font-stack(t.sans-fonts, ("sans-serif",)),
    "__FONT_MONO__": _css-font-stack(t.mono-fonts, (
      "ui-monospace",
      "monospace",
    )),
    "__BG_LIGHT__": css-oklch(t.paper-light),
    "__FG_LIGHT__": css-oklch(t.text-light),
    "__MUTED_LIGHT__": css-oklch(t.muted-light),
    "__LINE_LIGHT__": css-oklch(t.border-light),
    "__FRAME_LIGHT__": css-oklch(t.frame-light),
    "__SURF1_LIGHT__": css-oklch(t.surface-1-light),
    "__SURF2_LIGHT__": css-oklch(t.surface-2-light),
    "__BG_DARK__": css-oklch(t.paper-dark),
    "__FG_DARK__": css-oklch(t.text-dark),
    "__MUTED_DARK__": css-oklch(t.muted-dark),
    "__LINE_DARK__": css-oklch(t.border-dark),
    "__FRAME_DARK__": css-oklch(t.frame-dark),
    "__SURF1_DARK__": css-oklch(t.surface-1-dark),
    "__SURF2_DARK__": css-oklch(t.surface-2-dark),
  )
  token-map
    .pairs()
    .fold(read("style.css"), (css, pair) => css.replace(pair.at(0), pair.at(1)))
}
