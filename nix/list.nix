# ext/list.nix — appendo + membero relational list operations [L7a]
# Cons-cell representation: {h; t} / nil={_nil=true}
# Uses disjFin (non-interleaving) so failing queries terminate.
# Trade-off: run n on deterministic relations yields 1 answer, not n duplicates.
ukanren:
let
  inherit (ukanren) eq fresh conj;

  # non-interleaving mplus: depth-first, terminates on finite failure
  mplusFin =
    s1: s2:
    if s1 == null then
      s2
    else
      {
        inherit (s1) head;
        tail = mplusFin s1.tail s2;
      };

  disjFin =
    g1: g2: state:
    mplusFin (g1 state) (g2 state);

  cons = h: t: { inherit h t; };
  nil = {
    _nil = true;
  };

  fromList = lst: if lst == [ ] then nil else cons (builtins.head lst) (fromList (builtins.tail lst));

  toList = term: if term == nil then [ ] else [ term.h ] ++ toList term.t;

  appendo =
    l: r: o:
    disjFin (conj (eq l nil) (eq r o)) (
      fresh (h: fresh (t: fresh (zs: conj (eq l (cons h t)) (conj (eq o (cons h zs)) (appendo t r zs)))))
    );

  membero = x: lst: fresh (h: fresh (t: conj (eq lst (cons h t)) (disjFin (eq h x) (membero x t))));
in
{
  inherit
    appendo
    membero
    fromList
    toList
    cons
    nil
    ;
}
