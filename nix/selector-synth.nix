# ext/selector-synth.nix — bidirectional selector synthesis
# Innovation #7: synthSelectorGoal is relational (run/chrRun to enumerate).
# bankSynthSelector uses defBank for memoized enumeration.
ukanren:
let
  inherit (ukanren) pruneBy eq;
  fail = _: null;

  matchesSel =
    sel: node:
    if sel ? star then
      true
    else if sel ? attr then
      node ? "${sel.attr}"
    else if sel ? attrs then
      builtins.all (k: (node.${k} or null) == sel.attrs.${k}) (builtins.attrNames sel.attrs)
    else
      false;

  allKeys = nodes: pruneBy (x: x) (builtins.concatLists (builtins.map builtins.attrNames nodes));

  allKVPairs =
    nodes:
    pruneBy (p: "${p.k}=${builtins.toString p.v}") (
      builtins.concatLists (
        builtins.map (
          node:
          builtins.map (k: {
            inherit k;
            v = node.${k};
          }) (builtins.attrNames node)
        ) nodes
      )
    );

  candidates =
    nodes:
    let
      kvs = allKVPairs nodes;
    in
    [ { star = true; } ]
    ++ builtins.map (k: { attr = k; }) (allKeys nodes)
    ++ builtins.map (p: {
      attrs = {
        ${p.k} = p.v;
      };
    }) kvs;

  disjN =
    goals:
    builtins.foldl' (
      acc: g: state:
      ukanren.mplus (acc state) (g state)
    ) fail goals;

  validCands =
    positives: negatives:
    let
      allNodes = positives ++ negatives;
    in
    builtins.filter (
      sel: builtins.all (matchesSel sel) positives && builtins.all (n: !(matchesSel sel n)) negatives
    ) (candidates allNodes);

  # Relational: q unifies with each valid selector. use run/chrRun to enumerate.
  synthSelectorGoal =
    positives: negatives: q:
    disjN (builtins.map (c: eq q c) (validCands positives negatives));

  # bankSynthSelector: defBank memoizes selector enumeration (efficient repeated queries)
  bankSynthSelector =
    positives: negatives:
    let
      vc = validCands positives negatives;
      banked = ukanren.defBank 1 (cvars: disjN (builtins.map (c: eq (builtins.head cvars) c) vc));
    in
    q: banked [ q ];
in
{
  inherit candidates synthSelectorGoal bankSynthSelector;

  synthSelector = positives: negatives: validCands positives negatives;
}
