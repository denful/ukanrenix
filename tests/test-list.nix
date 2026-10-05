# tests/test-list.nix — oracle + negative controls for ext/list [L7a]
ukanren:
let
  inherit (ukanren)
    run
    appendo
    membero
    fromList
    toList
    ;
in
{
  "list" = {

    # appendo forward: unique output
    "test-appendo-forward" = {
      expr =
        let
          results = run 1 (
            q:
            appendo (fromList [
              1
              2
            ]) (fromList [ 3 ]) q
          );
        in
        builtins.map toList results;
      expected = [
        [
          1
          2
          3
        ]
      ];
    };

    # appendo backward: unique prefix
    "test-appendo-backward" = {
      expr =
        let
          results = run 1 (
            q:
            appendo q (fromList [ 3 ]) (fromList [
              1
              2
              3
            ])
          );
        in
        builtins.map toList results;
      expected = [
        [
          1
          2
        ]
      ];
    };

    # membero enumeration: first 2 elements
    "test-membero-enum" = {
      expr = run 2 (
        q:
        membero q (fromList [
          1
          2
          3
        ])
      );
      expected = [
        1
        2
      ];
    };

    # negative: appendo [1] [2] [9 9] fails
    "test-appendo-neg" = {
      expr = run 1 (
        _q:
        appendo (fromList [ 1 ]) (fromList [ 2 ]) (fromList [
          9
          9
        ])
      );
      expected = [ ];
    };

    # negative: membero 9 [1 2 3] fails
    "test-membero-neg" = {
      expr = run 1 (
        _q:
        membero 9 (fromList [
          1
          2
          3
        ])
      );
      expected = [ ];
    };

  };
}
