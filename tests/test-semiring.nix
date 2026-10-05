# Oracle for rung 4: ext/semiring (weighted search) [L015].
# RED until ext/semiring.nix implemented.
ukanren:
let
  inherit (ukanren)
    eq
    conj
    disj
    weight
    wrun
    wrunFull
    ;
in
{
  "semiring" = {

    # --- weight decorates answers ---

    "test-weight-basic" = {
      # answer has accumulated weight
      expr = (builtins.head (wrunFull 1 (q: weight 5 (eq q "x")))).weight;
      expected = 5;
    };

    "test-weight-zero-default" = {
      # no weight annotation → weight 0
      expr = (builtins.head (wrunFull 1 (q: eq q "y"))).weight;
      expected = 0;
    };

    "test-conj-accumulates-weight" = {
      # conj adds weights: 3 + 2 = 5
      expr =
        (builtins.head (wrunFull 1 (q: conj (weight 3 (eq q "x")) (weight 2 ukanren.succeed)))).weight;
      expected = 5;
    };

    # --- wrun sorts by weight ---

    "test-wrun-min-first" = {
      # disj: g1=expensive(w=10), g2=cheap(w=2); wrun returns cheap first
      expr = builtins.head (wrun 2 (q: disj (weight 10 (eq q "expensive")) (weight 2 (eq q "cheap"))));
      expected = "cheap";
    };

    "test-wrun-sorted-order" = {
      # full sorted order
      expr = builtins.map (x: x.answer) (
        wrunFull 3 (
          q: disj (weight 5 (eq q "mid")) (disj (weight 10 (eq q "high")) (weight 1 (eq q "low")))
        )
      );
      expected = [
        "low"
        "mid"
        "high"
      ];
    };

    "test-wrun-equal-weights" = {
      # equal weights → stream order preserved
      expr = wrun 2 (q: disj (eq q "a") (eq q "b"));
      expected = [
        "a"
        "b"
      ];
    };

  };
}
