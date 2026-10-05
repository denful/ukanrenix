# Oracle for rung 6: ext/staged (relational expression evaluator) [L016].
# RED until ext/staged.nix implemented.
# Expr lang: {atom=v} | {ref="name"} | {add=[e1,e2]}
# Holes = fresh vars used as expr or sub-expr.
ukanren:
let
  inherit (ukanren) run evalExpr;
in
{
  "staged" = {

    # --- forward eval (ground expr, ground env) ---

    "test-eval-atom" = {
      expr = run 1 (q: evalExpr { atom = 42; } { } q);
      expected = [ 42 ];
    };

    "test-eval-ref" = {
      expr = run 1 (q: evalExpr { ref = "x"; } { x = 5; } q);
      expected = [ 5 ];
    };

    "test-eval-add" = {
      expr = run 1 (
        q:
        evalExpr {
          add = [
            { atom = 3; }
            { atom = 4; }
          ];
        } { } q
      );
      expected = [ 7 ];
    };

    "test-eval-add-ref" = {
      # add with ref lookup
      expr = run 1 (
        q:
        evalExpr {
          add = [
            { ref = "a"; }
            { atom = 10; }
          ];
        } { a = 2; } q
      );
      expected = [ 12 ];
    };

    "test-eval-nested-add" = {
      # (1+2)+3 = 6
      expr = run 1 (
        q:
        evalExpr {
          add = [
            {
              add = [
                { atom = 1; }
                { atom = 2; }
              ];
            }
            { atom = 3; }
          ];
        } { } q
      );
      expected = [ 6 ];
    };

    # --- backward: unknown val operand ---

    "test-backward-atom" = {
      # q is hole for atom value
      expr = run 1 (q: evalExpr { atom = q; } { } 99);
      expected = [ 99 ];
    };

    "test-backward-add-leaf" = {
      # 3 + ? = 7  → ? = 4
      expr = run 1 (
        q:
        evalExpr {
          add = [
            { atom = 3; }
            { atom = q; }
          ];
        } { } 7
      );
      expected = [ 4 ];
    };

    "test-backward-add-left-leaf" = {
      # ? + 5 = 8  → ? = 3
      expr = run 1 (
        q:
        evalExpr {
          add = [
            { atom = q; }
            { atom = 5; }
          ];
        } { } 8
      );
      expected = [ 3 ];
    };

    # attrs expr: forward — build attrset from sub-exprs
    "test-attrs-forward" = {
      expr = run 1 (
        q:
        evalExpr {
          attrs = {
            port = {
              atom = 443;
            };
            host = {
              atom = "localhost";
            };
          };
        } { } q
      );
      expected = [
        {
          port = 443;
          host = "localhost";
        }
      ];
    };

    # attrs expr: backward — desired attrset constrains ref vars
    "test-attrs-backward-ref" = {
      expr = run 1 (
        hostVar:
        evalExpr {
          attrs = {
            host = {
              ref = "h";
            };
          };
        } { h = hostVar; } { host = "myhost"; }
      );
      expected = [ "myhost" ];
    };

  };
}
