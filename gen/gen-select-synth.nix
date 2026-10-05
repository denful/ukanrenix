# gen-select-synth.nix — selector synthesis returning gen-select native values
# ukanren: genSelect: → { synthSelector }
#
# synthSelector positives negatives n
#   positives = list of node attrsets that MUST match
#   negatives = list of node attrsets that MUST NOT match
#   n         = max selectors to return
#   Returns: list of gen-select selector values ({__sel=...})
#
# Enumerates concrete shapes: star, attrs{k=v} for each key+value in positives.
# Uses genSelect.matches for oracle verification.
_ukanren: genSelect:
let
  take =
    n: list:
    if n == 0 || list == [ ] then
      [ ]
    else
      [ (builtins.head list) ] ++ take (n - 1) (builtins.tail list);

  plainCtx = node: {
    data = _: node;
    parent = _: null;
    children = _: [ ];
    ancestors = _: [ ];
    siblings = _: [ ];
    inFlight = [ ];
  };

  matchesNode = sel: node: genSelect.matches sel "node" (plainCtx node);
  allMatch = sel: nodes: builtins.all (matchesNode sel) nodes;
  noneMatch = sel: nodes: builtins.all (n: !(matchesNode sel n)) nodes;

  # Collect all {k=v} pairs from positives
  kvPairs =
    nodes:
    builtins.concatMap (
      node:
      builtins.map (k: {
        key = k;
        val = node.${k};
      }) (builtins.attrNames node)
    ) nodes;

  # Build candidate selectors: star + one attrs{k=v} per unique kv pair
  candidates =
    positives:
    let
      pairs = kvPairs positives;
      attrSels = builtins.map (kv: {
        __sel = "attrs";
        a = {
          ${kv.key} = kv.val;
        };
      }) pairs;
    in
    [ { __sel = "star"; } ] ++ attrSels;

  synthSelector =
    positives: negatives: n:
    let
      valid = builtins.filter (sel: allMatch sel positives && noneMatch sel negatives) (
        candidates positives
      );
    in
    take n valid;
in
{
  inherit synthSelector;
}
