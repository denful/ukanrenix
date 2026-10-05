# Oracle for rung 2: ext/bank (defBank + pruneBy).
# RED until ext/bank.nix implemented.
ukanren:
let
  inherit (ukanren)
    run
    eq
    fresh
    conj
    disj
    defBank
    pruneBy
    ;

  # relation: q is one of "a", "b", "c"
  abc = defBank 1 (
    cvs:
    let
      q = builtins.head cvs;
    in
    disj (eq q "a") (disj (eq q "b") (eq q "c"))
  );

  # relation: pair [a b] where a ∈ {1,2}, b = 0
  pair01 = defBank 2 (
    cvs:
    let
      a = builtins.elemAt cvs 0;
      b = builtins.elemAt cvs 1;
    in
    conj (disj (eq a 1) (eq a 2)) (eq b 0)
  );
in
{
  "bank" = {

    # --- defBank ---

    "test-bank-var-arg" = {
      # banked relation with var arg gives same answers as naive disj
      expr = run 3 (q: abc [ q ]);
      expected = [
        "a"
        "b"
        "c"
      ];
    };

    "test-bank-ground-hit" = {
      # ground arg that IS in bank → succeeds
      expr = run 1 (q: conj (abc [ "b" ]) (eq q "yes"));
      expected = [ "yes" ];
    };

    "test-bank-ground-miss" = {
      # ground arg NOT in bank → fails
      expr = run 1 (q: conj (abc [ "x" ]) (eq q "yes"));
      expected = [ ];
    };

    "test-bank-2var" = {
      # 2-canonical-var bank: enumerate pairs
      expr = run 2 (
        q:
        fresh (
          a:
          fresh (
            b:
            conj
              (pair01 [
                a
                b
              ])
              (
                eq q [
                  a
                  b
                ]
              )
          )
        )
      );
      expected = [
        [
          1
          0
        ]
        [
          2
          0
        ]
      ];
    };

    "test-bank-partial-ground" = {
      # one arg ground, one var → filters canonical answers
      expr = run 1 (
        q:
        pair01 [
          1
          q
        ]
      );
      expected = [ 0 ];
    };

    # --- pruneBy ---

    "test-prune-dedup" = {
      # infinite disj stream, prune to unique values
      expr = pruneBy (x: x) (run 6 (q: disj (eq q "a") (eq q "b")));
      expected = [
        "a"
        "b"
      ];
    };

    "test-prune-keeps-first" = {
      expr = pruneBy (x: x) [
        "a"
        "b"
        "a"
        "c"
        "b"
      ];
      expected = [
        "a"
        "b"
        "c"
      ];
    };

    "test-prune-by-key" = {
      # prune list of pairs by first element
      expr = pruneBy builtins.head [
        [
          1
          9
        ]
        [
          2
          8
        ]
        [
          1
          7
        ]
        [
          3
          6
        ]
      ];
      expected = [
        [
          1
          9
        ]
        [
          2
          8
        ]
        [
          3
          6
        ]
      ];
    };

  };
}
