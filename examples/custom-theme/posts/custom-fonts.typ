#import "@preview/typica:0.1.0": *

#show: post.with(
  title: [Customizing Fonts & Perceptual Palette],
  subtitle: [One `theme` dictionary drives both generated CSS and paged previews],
  author: "Ada Lovelace",
  created: datetime(year: 2026, month: 10, day: 15),
  summary: [Swapping font stacks and warm-paper oklch tokens without editing CSS.],
  tags: ("typography", "oklch", "theming"),
)

Overriding `serif-fonts`, `math-fonts`, `sans-fonts`, or `mono-fonts` in `site.with(theme: (...))` updates both the HTML stylesheet variables (`--serif`, `--math`, `--sans`, `--mono`) and paged Typst `set text(font: ...)` rules#sidenote[When `font-faces: auto`, `typica` automatically omits unused built-in `@font-face` declarations.].

= Euler's Identity <euler>

$ e^(i pi) + 1 = 0 $
