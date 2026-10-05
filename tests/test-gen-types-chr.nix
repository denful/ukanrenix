# tests/test-gen-types-chr.nix — gen-types-chr using mock genTypes
ukanren:
let
  # Minimal mock satisfying gen-types verify protocol: null=ok, str=error
  mockGenTypes = {
    int = {
      verify = v: if builtins.isInt v then null else "not int";
    };
    str = {
      verify = v: if builtins.isString v then null else "not str";
    };
    bool = {
      verify = v: if builtins.isBool v then null else "not bool";
    };
    listOf = _: { verify = v: if builtins.isList v then null else "not list"; };
    nullOr = _: { verify = v: if v == null then null else null; };
  };
  chr = import ../gen/gen-types-chr.nix ukanren mockGenTypes;
  inherit (ukanren) run eq conj;
in
{
  "gen-types-chr" = {
    "test-int-pass" = {
      expr = run 1 (q: conj (chr.intGoal q) (eq q 42));
      expected = [ 42 ];
    };
    "test-int-fail-on-string" = {
      expr = run 1 (q: conj (eq q "bad") (chr.intGoal q));
      expected = [ ];
    };
    "test-str-pass" = {
      expr = run 1 (q: conj (chr.strGoal q) (eq q "hello"));
      expected = [ "hello" ];
    };
    "test-str-fail-on-int" = {
      expr = run 1 (q: conj (eq q 99) (chr.strGoal q));
      expected = [ ];
    };
    "test-deferred-while-unbound" = {
      # typeGoal on fresh var → deferred, does not fail
      expr = builtins.length (run 1 (q: chr.intGoal q)) > 0;
      expected = true;
    };
    "test-bool-pass" = {
      expr = run 1 (q: conj (chr.boolGoal q) (eq q true));
      expected = [ true ];
    };
  };
}
