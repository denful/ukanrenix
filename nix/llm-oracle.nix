# nix/gen-llm-oracle.nix — LLM output completion via weighted ukanren search [rung-9d]
ukanren:
let
  inherit (ukanren) eq conj fresh;

  fail = _: null;

  typeMatch = val: expected: builtins.typeOf val == expected;

  # instanceGoal: all ground fields satisfy schema type strings
  instanceGoal =
    schema: inst:
    let
      fields = builtins.attrNames schema;
      checks = builtins.map (
        f:
        if inst ? ${f} && !(ukanren.isVar inst.${f}) then
          if typeMatch inst.${f} schema.${f} then ukanren.succeed else ukanren.fail
        else
          ukanren.succeed
      ) fields;
    in
    builtins.foldl' ukanren.conj ukanren.succeed checks;

  # llmComplete schema partial q:
  # goal — q is a full completion of partial attrset satisfying schema.
  # Fields present in partial: kept as-is (weight 0).
  # Fields absent from partial: fresh var, weight 1 (invented).
  # Ground values in partial that violate schema types → fail immediately.
  llmComplete =
    schema: partial: q:
    let
      fields = builtins.attrNames schema;
      # Check if any ground partial value conflicts with schema types
      groundConflict = builtins.any (
        field:
        builtins.hasAttr field partial
        && !(ukanren.isVar partial.${field})
        && !(typeMatch partial.${field} schema.${field})
      ) fields;
      wrap =
        field: inner: acc:
        if builtins.hasAttr field partial then
          inner (acc // { ${field} = partial.${field}; })
        else
          fresh (v: ukanren.weight 1 (inner (acc // { ${field} = v; })));
      base = acc: conj (eq q acc) (instanceGoal schema acc);
      goal = builtins.foldl' (inner: field: wrap field inner) base fields;
    in
    if groundConflict then fail else goal { };

  # rankedComplete schema partial n: top-n completions by ascending weight (fewest invented fields)
  rankedComplete =
    schema: partial: n:
    ukanren.wrun n (llmComplete schema partial);

  # rankedCompleteFull schema partial n: like rankedComplete but returns [{answer weight}]
  rankedCompleteFull =
    schema: partial: n:
    ukanren.wrunFull n (llmComplete schema partial);
in
{
  inherit llmComplete rankedComplete rankedCompleteFull;
}
