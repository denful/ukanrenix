# tests/test-gen-select-synth.nix — gen-select-synth using mock genSelect
ukanren:
let
  # Mock genSelect.matches: understands __sel=star and __sel=attrs
  mockMatches =
    sel: _nodeId: ctx:
    let
      node = ctx.data null;
    in
    if sel == { __sel = "star"; } then
      true
    else if sel ? __sel && sel.__sel == "attrs" then
      builtins.all (k: node ? ${k} && node.${k} == sel.a.${k}) (builtins.attrNames sel.a)
    else
      false;
  mockGenSelect = {
    matches = mockMatches;
  };
  ss = import ../gen/gen-select-synth.nix ukanren mockGenSelect;

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
  "gen-select-synth" = {
    # Role attr selector found for web vs db
    "test-role-attrs-selector-found" = {
      expr = builtins.elem {
        __sel = "attrs";
        a = {
          role = "web";
        };
      } (ss.synthSelector [ web1 web2 ] [ db1 ] 5);
      expected = true;
    };
    # Star not returned when negatives exist
    "test-no-star-with-negatives" = {
      expr = builtins.elem { __sel = "star"; } (ss.synthSelector [ web1 ] [ db1 ] 5);
      expected = false;
    };
    # Identical positive and negative → no selector
    "test-identical-positive-negative" = {
      expr = ss.synthSelector [ { role = "web"; } ] [ { role = "web"; } ] 5;
      expected = [ ];
    };
    # Star returned when no negatives
    "test-star-with-no-negatives" = {
      expr = builtins.elem { __sel = "star"; } (ss.synthSelector [ web1 ] [ ] 5);
      expected = true;
    };
    # Output values are gen-select native (__sel tagged attrsets)
    "test-output-is-gen-select-native" = {
      expr =
        let
          results = ss.synthSelector [ web1 ] [ db1 ] 3;
        in
        builtins.all (s: s ? __sel) results;
      expected = true;
    };
  };
}
