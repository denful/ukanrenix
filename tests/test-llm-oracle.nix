ukanren:
let
  glo = ukanren;
  schema = {
    host = "string";
    port = "int";
    scheme = "string";
  };
in
{
  "gen-llm-oracle" = {

    # 1. Full partial (all fields given) → 1 result, exact match
    "test-complete-full-partial" = {
      expr =
        let
          r = builtins.head (
            glo.rankedComplete schema {
              host = "example.com";
              port = 443;
              scheme = "https";
            } 1
          );
        in
        r.host == "example.com" && r.port == 443 && r.scheme == "https";
      expected = true;
    };

    # 2. Partial missing one field → result has all 3 fields
    "test-complete-one-missing" = {
      expr =
        let
          r = builtins.head (
            glo.rankedComplete schema {
              host = "example.com";
              port = 443;
            } 1
          );
        in
        r ? scheme && r.host == "example.com" && r.port == 443;
      expected = true;
    };

    # 3. rankedCompleteFull: full partial weight=0, missing-field partial weight=1
    "test-weight-full-vs-partial" = {
      expr =
        let
          w0 =
            (builtins.head (
              glo.rankedCompleteFull schema {
                host = "a";
                port = 1;
                scheme = "http";
              } 1
            )).weight;
          w1 =
            (builtins.head (
              glo.rankedCompleteFull schema {
                host = "a";
                port = 1;
              } 1
            )).weight;
        in
        w0 == 0 && w1 == 1;
      expected = true;
    };

    # 4. rankedComplete returns multiple completions when partial is empty (all invented)
    "test-multiple-completions" = {
      expr = builtins.length (glo.rankedComplete schema { } 3) > 0;
      expected = true;
    };

    # 5. NEGATIVE: partial has type conflict (port="bad" but schema says "int") → []
    "test-type-conflict" = {
      expr = glo.rankedComplete schema { port = "bad"; } 1;
      expected = [ ];
    };

  };
}
