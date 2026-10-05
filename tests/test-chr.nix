# Oracle for rung 3: ext/chr (CHR — constraint handling rules) [L013].
# RED until ext/chr.nix implemented.
ukanren:
let
  inherit (ukanren)
    eq
    conj
    disj
    typeOf
    diseq
    chrRun
    ;
in
{
  "chr" = {

    # --- typeOf ---

    "test-typeOf-int-pass" = {
      expr = chrRun 1 (q: conj (typeOf q "int") (eq q 42));
      expected = [ 42 ];
    };

    "test-typeOf-int-fail" = {
      expr = chrRun 1 (q: conj (typeOf q "int") (eq q "hello"));
      expected = [ ];
    };

    "test-typeOf-string-pass" = {
      expr = chrRun 1 (q: conj (typeOf q "string") (eq q "hi"));
      expected = [ "hi" ];
    };

    "test-typeOf-unbound-deferred" = {
      # unbound q → constraint deferred → answer returned (q is still a var)
      expr = builtins.length (chrRun 1 (q: typeOf q "string"));
      expected = 1;
    };

    # --- diseq ---

    "test-diseq-pass" = {
      expr = chrRun 1 (q: conj (diseq q 42) (eq q 99));
      expected = [ 99 ];
    };

    "test-diseq-fail" = {
      expr = chrRun 1 (q: conj (diseq q 42) (eq q 42));
      expected = [ ];
    };

    "test-diseq-unbound-deferred" = {
      expr = builtins.length (chrRun 1 (q: diseq q 42));
      expected = 1;
    };

    # --- filtering over stream ---

    "test-filter-stream" = {
      # diseq filters: no answer should equal 2
      expr = builtins.filter (x: x == 2) (
        chrRun 4 (q: conj (diseq q 2) (disj (eq q 1) (disj (eq q 2) (eq q 3))))
      );
      expected = [ ];
    };

    # --- conj of constraints ---

    "test-conj-constraints-fail" = {
      # typeOf int AND diseq 42 but eq 42 → fails (diseq fires)
      expr = chrRun 1 (q: conj (typeOf q "int") (conj (diseq q 42) (eq q 42)));
      expected = [ ];
    };

    "test-conj-constraints-pass" = {
      # typeOf int AND diseq 42, eq 99 → passes both
      expr = chrRun 1 (q: conj (typeOf q "int") (conj (diseq q 42) (eq q 99)));
      expected = [ 99 ];
    };

  };
}
