# Oracle tests for ext/selector-synth.nix
ukanren:
let
  inherit (ukanren) synthSelector;

  web1 = {
    role = "web";
    env = "prod";
  };
  web2 = {
    role = "web";
    env = "staging";
  };
  db1 = {
    role = "db";
    env = "prod";
  };
in
{
  "selector-synth" = {
    "test-role-discriminates-web-from-db" = {
      # attrs={role=web} matches both web nodes but not db1 (role=db)
      expr = builtins.elem {
        attrs = {
          role = "web";
        };
      } (synthSelector [ web1 web2 ] [ db1 ]);
      expected = true;
    };
    "test-no-star-when-negatives-exist" = {
      expr = builtins.elem { star = true; } (synthSelector [ web1 ] [ db1 ]);
      expected = false;
    };
    "test-single-positive-has-discriminator" = {
      expr = builtins.length (synthSelector [ web1 ] [ db1 ]) > 0;
      expected = true;
    };
    "test-negative-control-identical-nodes" = {
      expr =
        synthSelector
          [
            {
              role = "web";
              env = "prod";
            }
          ]
          [
            {
              role = "web";
              env = "prod";
            }
          ];
      expected = [ ];
    };
    "test-attrval-selector-role-web" = {
      expr = builtins.elem {
        attrs = {
          role = "web";
        };
      } (synthSelector [ web1 web2 ] [ db1 ]);
      expected = true;
    };

    # RELATIONAL: synthSelectorGoal enumerates valid selectors via run
    "test-synth-selector-goal-enumerates" = {
      expr =
        let
          results = ukanren.chrRun 10 (ukanren.synthSelectorGoal [ web1 web2 ] [ db1 ]);
        in
        builtins.length results > 0
        && builtins.elem {
          attrs = {
            role = "web";
          };
        } results;
      expected = true;
    };

    # RELATIONAL: synthSelectorGoal negative control — no valid selector
    "test-synth-selector-goal-empty" = {
      expr = ukanren.chrRun 5 (ukanren.synthSelectorGoal [ { role = "web"; } ] [ { role = "web"; } ]);
      expected = [ ];
    };

    # BANK: bankSynthSelector produces same results as synthSelector
    "test-bank-synth-selector-match" = {
      expr =
        let
          bankedGoal = ukanren.bankSynthSelector [ web1 web2 ] [ db1 ];
          results = ukanren.chrRun 10 bankedGoal;
        in
        builtins.elem {
          attrs = {
            role = "web";
          };
        } results;
      expected = true;
    };

    # BANK: memoized — goal called twice, same results
    "test-bank-synth-selector-idempotent" = {
      expr =
        let
          bankedGoal = ukanren.bankSynthSelector [ web1 ] [ db1 ];
          r1 = ukanren.chrRun 10 bankedGoal;
          r2 = ukanren.chrRun 10 bankedGoal;
        in
        r1 == r2;
      expected = true;
    };
  };
}
