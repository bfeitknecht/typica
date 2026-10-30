#import "@preview/typica:0.1.0": *

#show: post.with(
  title: [Normal Order & Church–Rosser],
  subtitle: [Confluence of untyped $lambda$-reduction in twenty lines],
  author: "Ada Lovelace",
  monograph: "EWD-01",
  created: datetime(year: 2026, month: 10, day: 12),
  summary: [A compact demonstration of definitions, theorems, sidenotes, and code listings in typica.],
  tags: ("lambda", "pl", "confluence"),
)

Untyped $lambda$-terms evolve by $beta$-reduction#sidenote[Capture-avoiding substitution $M[x := N]$ renames bound variables as needed.]: $(lambda x. M) N ->_beta M[x := N]$.

= Confluence <confluence>

#definition[Diamond Property][
  A binary relation $->$ on terms satisfies the _diamond property_ when $M -> N_1$ and $M -> N_2$ imply the existence of a common reduct $P$ with $N_1 -> P$ and $N_2 -> P$.
]

#theorem[Church–Rosser][
  Multi-step $beta$-reduction $->>_beta$ is confluent: if $M ->>_beta N_1$ and $M ->>_beta N_2$, there exists $P$ such that $N_1 ->>_beta P$ and $N_2 ->>_beta P$.
]

#proof[
  Tait and Martin-Löf's parallel reduction $=>$ satisfies the single-step diamond property by structural induction on $M$, and its reflexive-transitive closure coincides with $->>_beta$.
]

```ocaml
type term = Var of string | Abs of string * term | App of term * term
```
