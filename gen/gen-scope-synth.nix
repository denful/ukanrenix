# gen-scope-synth.nix — scope-graph decl synthesis via forward oracle
# _ukanren: genScope: → { synthDecls }
#
# synthDecls nodeIds parentGraph attrDefs desired candidateDecls n
#   nodeIds       = list of node id strings (for parentGraph construction)
#   parentGraph   = gen-scope algebraic graph (overlay/vertex/connect)
#   attrDefs      = { attrName = self: id: value; } — the attribute grammar
#   desired       = [ { id; attr; value; } ] — required attribute evaluations
#   candidateDecls = [ { nodeId → attrset } ] — decl assignments to search
#   n             = max solutions
#   Returns: [{weight; answer}] sorted ascending by total declared field count
#
# Oracle: genScope.eval {} attrDefs (genScope.buildRoots {parentGraph; decls})
# Weight: total number of decl fields (fewer = simpler / more minimal)
_ukanren: genScope:
let
  take =
    n: list:
    if n == 0 || list == [ ] then
      [ ]
    else
      [ (builtins.head list) ] ++ take (n - 1) (builtins.tail list);

  fieldCount =
    decls:
    builtins.foldl' (acc: k: acc + builtins.length (builtins.attrNames (decls.${k} or { }))) 0 (
      builtins.attrNames decls
    );

  satisfies = result: desired: builtins.all (req: result.get req.id req.attr == req.value) desired;

  oracle =
    parentGraph: attrDefs: decls:
    genScope.eval { } attrDefs (genScope.buildRoots { inherit parentGraph decls; });

  synthDecls =
    _nodeIds: parentGraph: attrDefs: desired: candidateDecls: n:
    let
      valid = builtins.filter (d: satisfies (oracle parentGraph attrDefs d) desired) candidateDecls;
      ranked = builtins.sort (a: b: fieldCount a < fieldCount b) valid;
    in
    take n (
      builtins.map (d: {
        weight = fieldCount d;
        answer = d;
      }) ranked
    );
in
{
  inherit synthDecls;
}
