# tests/test-gen-scope-synth.nix — gen-scope-synth using mock genScope
ukanren:
let
  # Minimal mock: buildRoots stores decls, eval applies attrDefs via self.node
  mockGenScope = {
    vertex = id: { ids = [ id ]; };
    overlay = g1: g2: { ids = g1.ids ++ g2.ids; };
    buildRoots =
      { parentGraph, decls, ... }:
      {
        inherit decls;
        nodes = parentGraph;
      };
    eval =
      _opts: attrDefs: roots:
      let
        self = {
          node = id: {
            decls = roots.decls.${id} or { };
            inherit id;
          };
          get = id: attr: (attrDefs.${attr} or (_: _: null)) self id;
        };
      in
      {
        get = id: attr: (attrDefs.${attr} or (_: _: null)) self id;
      };
  };

  ss = import ../gen/gen-scope-synth.nix ukanren mockGenScope;

  # Attribute grammar: region reads directly from node's decls
  attrDefs = {
    region = self: id: (self.node id).decls.region or null;
    env = self: id: (self.node id).decls.env or null;
  };

  graph = mockGenScope.overlay (mockGenScope.vertex "host:web") (mockGenScope.vertex "host:db");

  # Candidate decls to search over
  candidates = [
    { }
    {
      "host:web" = {
        region = "us-east";
      };
    }
    {
      "host:web" = {
        region = "eu-west";
      };
    }
    {
      "host:web" = {
        region = "us-east";
        env = "prod";
      };
    }
    {
      "host:db" = {
        region = "us-east";
      };
    }
  ];
in
{
  "gen-scope-synth" = {
    # Single desired attr — correct decls found
    "test-single-desired-found" = {
      expr =
        let
          desired = [
            {
              id = "host:web";
              attr = "region";
              value = "us-east";
            }
          ];
          r = ss.synthDecls [ "host:web" "host:db" ] graph attrDefs desired candidates 3;
        in
        (builtins.head r).answer."host:web".region;
      expected = "us-east";
    };
    # Minimal weight first (fewer fields)
    "test-minimal-first" = {
      expr =
        let
          desired = [
            {
              id = "host:web";
              attr = "region";
              value = "us-east";
            }
          ];
          r = ss.synthDecls [ "host:web" ] graph attrDefs desired candidates 3;
        in
        (builtins.head r).weight;
      expected = 1;
    };
    # No candidates satisfy → []
    "test-impossible-desired" = {
      expr =
        let
          desired = [
            {
              id = "host:web";
              attr = "region";
              value = "ap-south";
            }
          ];
        in
        ss.synthDecls [ "host:web" ] graph attrDefs desired candidates 3;
      expected = [ ];
    };
    # Empty desired → all candidates pass; empty decls first (weight 0)
    "test-empty-desired-weight-zero-first" = {
      expr =
        let
          r = ss.synthDecls [ "host:web" ] graph attrDefs [ ] candidates 5;
        in
        (builtins.head r).weight;
      expected = 0;
    };
    # Multi-field decl ranked higher than single-field
    "test-multi-field-ranked-after" = {
      expr =
        let
          desired = [
            {
              id = "host:web";
              attr = "region";
              value = "us-east";
            }
          ];
          r = ss.synthDecls [ "host:web" ] graph attrDefs desired candidates 5;
          weights = builtins.map (x: x.weight) r;
          singleFirst = builtins.head weights == 1;
          hasTwoField = builtins.elem 2 weights;
        in
        singleFirst && hasTwoField;
      expected = true;
    };
    # Returns gen-scope native decls attrset
    "test-answer-is-decls-attrset" = {
      expr =
        let
          desired = [
            {
              id = "host:web";
              attr = "region";
              value = "us-east";
            }
          ];
          r = ss.synthDecls [ "host:web" ] graph attrDefs desired candidates 1;
        in
        builtins.isAttrs (builtins.head r).answer;
      expected = true;
    };
  };
}
