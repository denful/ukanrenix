# tests/test-gen-schema-synth.nix — gen-schema-synth using mock genMerge/genTypes
ukanren:
let
  mockInt = {
    verify = v: if builtins.isInt v then null else "not int";
  };
  mockStr = {
    verify = v: if builtins.isString v then null else "not str";
  };
  mockBool = {
    verify = v: if builtins.isBool v then null else "not bool";
  };
  mockGenTypes = {
    int = mockInt;
    str = mockStr;
    bool = mockBool;
    listOf = _: { verify = _: null; };
    nullOr = _: { verify = _: null; };
  };
  mockGenMerge = {
    types = {
      int = mockInt;
      str = mockStr;
      bool = mockBool;
    };
    mkOption = desc: desc; # identity — mkOption {type=...} → {type=...}
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
  synth = import ../gen/gen-schema-synth.nix ukanren mockGenMerge mockGenTypes;
in
{
  "gen-schema-synth" = {
    # synthFromOptions: desired field propagated
    "test-synth-desired-port" = {
      expr =
        let
          options = {
            port = mockGenMerge.mkOption { type = mockGenMerge.types.int; };
          };
          results = synth.synthFromOptions options { port = 443; } 1;
        in
        (builtins.head results).answer.port;
      expected = 443;
    };
    # synthFromOptions: type conflict → []
    "test-synth-type-conflict" = {
      expr =
        let
          options = {
            port = mockGenMerge.mkOption { type = mockGenMerge.types.int; };
          };
        in
        synth.synthFromOptions options { port = "bad"; } 1;
      expected = [ ];
    };
    # synthMinimalOverride: only differing fields
    "test-minimal-override-diff-only" = {
      expr =
        let
          options = {
            port = mockGenMerge.mkOption { type = mockGenMerge.types.int; };
            host = mockGenMerge.mkOption { type = mockGenMerge.types.str; };
          };
          base = {
            port = 80;
            host = "localhost";
          };
          over = synth.synthMinimalOverride base options {
            port = 443;
            host = "localhost";
          };
        in
        over.port == 443 && !(over ? host);
      expected = true;
    };
    # synthMinimalOverride: unchanged → {}
    "test-minimal-override-noop" = {
      expr =
        let
          options = {
            port = mockGenMerge.mkOption { type = mockGenMerge.types.int; };
          };
        in
        synth.synthMinimalOverride { port = 443; } options { port = 443; };
      expected = { };
    };
    # importSel: minimal schema wins (weight 0 = fully covered)
    "test-import-sel-weight" = {
      expr =
        let
          lib = [
            { port = mockGenMerge.mkOption { type = mockGenMerge.types.int; }; }
            {
              port = mockGenMerge.mkOption { type = mockGenMerge.types.int; };
              host = mockGenMerge.mkOption { type = mockGenMerge.types.str; };
            }
          ];
          r = builtins.head (synth.importSel lib { port = 443; } 3);
        in
        r.weight == 0 && builtins.length r.answer == 1;
      expected = true;
    };
    # importSel: type mismatch → no results
    "test-import-sel-type-mismatch" = {
      expr =
        let
          lib = [ { port = mockGenMerge.mkOption { type = mockGenMerge.types.int; }; } ];
        in
        synth.importSel lib { port = "bad"; } 3;
      expected = [ ];
    };
  };
}
