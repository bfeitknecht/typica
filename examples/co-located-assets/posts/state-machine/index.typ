#import "@preview/typica:0.1.0": *

#show: post.with(
  title: [Parity Automaton with Co-Located SVG],
  subtitle: [Grouping a post and its external assets in `posts/state-machine/`],
  author: "Ada Lovelace",
  created: datetime(year: 2026, month: 10, day: 18),
  summary: [Using a directory post so images and interactive files are emitted alongside `posts/state-machine/index.html`.],
  tags: ("automata", "svg", "bundles"),
  assets: (
    "dfa.svg": read("dfa.svg", encoding: none),
  ),
)

Because this post lives in `posts/state-machine/index.typ`, both `#image("dfa.svg")` (for paged previews) and `assets: ("dfa.svg": ...)` (emitted at `posts/state-machine/dfa.svg` in the HTML bundle) stay co-located in one folder:

= Even Parity over $\{0, 1\}^*$ <parity-dfa>

#figure(
  image("dfa.svg", width: 72%),
  caption: [Two-state deterministic finite automaton recognizing bitstrings with an even number of ones.],
)

Download the raw asset at #link("dfa.svg")[`dfa.svg`].
