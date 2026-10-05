# tests/test-gen-merge-backward.nix — gen-merge-backward using mock genMerge
ukanren:
let
  # Mock genMerge.evalModuleTree: fold .config attrs from each module
  mockGenMerge = {
    evalModuleTree =
      { modules, ... }:
      let
        cfg = builtins.foldl' (acc: m: acc // (m.config or { })) { } modules;
      in
      {
        config = cfg;
        options = { };
      };
  };
  mb = import ../gen/gen-merge-backward.nix ukanren mockGenMerge;

  modA = {
    config = {
      port = 80;
      host = "localhost";
    };
  };
  modB = {
    config = {
      port = 443;
      host = "example.com";
    };
  };
  modC = {
    config = {
      debug = true;
    };
  };
in
{
  "gen-merge-backward" = {
    # evalModuleo: merged result equals desired
    "test-evalmoduleo-forward" = {
      expr =
        let
          r = ukanren.run 1 (q: mb.evalModuleo [ modA ] q);
        in
        (builtins.head r).port;
      expected = 80;
    };
    # evalModuleo: two modules merged correctly
    "test-evalmoduleo-merge-two" = {
      expr =
        let
          r = ukanren.run 1 (q: mb.evalModuleo [ modA modB ] q);
        in
        (builtins.head r).port;
      expected = 443; # modB overrides modA
    };
    # synthFromModules: single module covers desired
    "test-synth-single-covers" = {
      expr =
        let
          results = mb.synthFromModules [ modA modB modC ] {
            port = 80;
            host = "localhost";
          } 3;
          cover = builtins.head results;
        in
        cover.answer == [ modA ];
      expected = true;
    };
    # synthFromModules: empty desired → empty module list (no modules needed)
    "test-synth-empty-desired" = {
      expr =
        let
          results = mb.synthFromModules [ modA modB ] { } 3;
        in
        builtins.length results > 0;
      expected = true;
    };
    # synthFromModules: no modules cover impossible desired → []
    "test-synth-impossible" = {
      expr = mb.synthFromModules [ modA modC ] { port = 9999; } 3;
      expected = [ ];
    };
  };
}
