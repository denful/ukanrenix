# Smoke tests = oracle for rung 1 (core kernel).
# nix-unit requires test names to start with "test"
ukanren:
let
  inherit (ukanren)
    run
    eq
    fresh
    conj
    disj
    succeed
    fail
    ;
in
{
  "smoke" = {

    # --- eq ---

    "test-eq-ground-match" = {
      expr = run 1 (q: eq q 42);
      expected = [ 42 ];
    };

    "test-eq-ground-fail" = {
      expr = run 1 (q: conj (eq q 1) (eq q 2));
      expected = [ ];
    };

    "test-eq-both-ground" = {
      expr = run 1 (q: conj (eq 3 3) (eq q "yes"));
      expected = [ "yes" ];
    };

    "test-eq-list-unify" = {
      expr = run 1 (
        q:
        fresh (
          a:
          conj (eq q [
            a
            2
          ]) (eq a 1)
        )
      );
      expected = [
        [
          1
          2
        ]
      ];
    };

    "test-eq-attrset-unify" = {
      expr = run 1 (q: fresh (v: conj (eq q { x = v; }) (eq v 99)));
      expected = [ { x = 99; } ];
    };

    # --- succeed / fail ---

    "test-succeed-gives-answer" = {
      expr = run 1 (q: conj succeed (eq q "ok"));
      expected = [ "ok" ];
    };

    "test-fail-gives-nothing" = {
      expr = run 1 (_: fail);
      expected = [ ];
    };

    # --- disj ---

    "test-disj-both" = {
      expr = run 2 (q: disj (eq q "a") (eq q "b"));
      expected = [
        "a"
        "b"
      ];
    };

    "test-disj-first-only" = {
      expr = run 1 (q: disj (eq q "first") (eq q "second"));
      expected = [ "first" ];
    };

    "test-disj-interleave" = {
      # disj interleaves — 5 answers from infinite stream of alternating a/b
      expr = run 5 (q: disj (eq q "a") (eq q "b"));
      expected = [
        "a"
        "b"
        "a"
        "b"
        "a"
      ];
    };

    # --- conj ---

    "test-conj-chain" = {
      expr = run 1 (
        q:
        fresh (
          a:
          fresh (
            b:
            conj (eq a 1) (
              conj (eq b 2) (
                eq q [
                  a
                  b
                ]
              )
            )
          )
        )
      );
      expected = [
        [
          1
          2
        ]
      ];
    };

    # --- run N ---

    "test-run-zero" = {
      expr = run 0 (q: eq q 1);
      expected = [ ];
    };

    "test-run-bounded-on-infinite" = {
      # infinite stream of 42s via disj self-loop
      expr = builtins.length (run 10 (q: disj (eq q 42) (eq q 42)));
      expected = 10;
    };

    # --- reify unbound var ---

    "test-reify-unbound" = {
      # unbound var stays as a var-shaped attrset
      expr =
        let
          answers = run 1 (_q: succeed);
          a = builtins.head answers;
        in
        a.__var or false;
      expected = true;
    };

  };
}
