# gen-schema-synth.nix — backward synthesis over gen-merge option declarations
# ukanren: genMerge: genTypes: → { synthFromOptions synthMinimalOverride importSel }
#
# synthFromOptions options desired n
#   options = attrset of gen-merge mkOption records (genMerge.mkOption {type=...})
#   desired = partial attrset of ground values
#   n       = max completions
#   Returns: [{weight; answer}] sorted ascending by invented-field count
#
# synthMinimalOverride base options desired
#   Returns: minimal override attrset (only fields differing from base)
#
# importSel schemaLib desired n
#   schemaLib = list of option-attrsets
#   Returns: [{weight; answer=[schema]}] sorted by invented-field count
_ukanren: genMerge: genTypes:
let
  take =
    n: list:
    if n == 0 || list == [ ] then
      [ ]
    else
      [ (builtins.head list) ] ++ take (n - 1) (builtins.tail list);

  checkerOf =
    optType:
    if optType == genMerge.types.int then
      genTypes.int
    else if optType == genMerge.types.str then
      genTypes.str
    else if optType == genMerge.types.bool then
      genTypes.bool
    else
      null;

  coversDesired =
    options: desired:
    builtins.all (
      f:
      options ? ${f}
      && (
        let
          c = checkerOf options.${f}.type;
        in
        c == null || c.verify desired.${f} == null
      )
    ) (builtins.attrNames desired);

  synthFromOptions =
    options: desired: n:
    let
      fields = builtins.attrNames options;
      inventedCount = builtins.length (builtins.filter (f: !(desired ? ${f})) fields);
      filled = builtins.foldl' (
        acc: f: if desired ? ${f} then acc // { ${f} = desired.${f}; } else acc
      ) { } fields;
    in
    if !(coversDesired options desired) then
      [ ]
    else
      builtins.genList (_: {
        weight = inventedCount;
        answer = filled;
      }) n;

  synthMinimalOverride =
    base: options: desired:
    let
      fields = builtins.attrNames options;
      overrideFields = builtins.filter (
        f: desired ? ${f} && (!(base ? ${f}) || base.${f} != desired.${f})
      ) fields;
    in
    builtins.listToAttrs (
      builtins.map (f: {
        name = f;
        value = desired.${f};
      }) overrideFields
    );

  importSel =
    schemaLib: desired: n:
    let
      rank = schema: {
        weight = builtins.length (builtins.filter (f: !(desired ? ${f})) (builtins.attrNames schema));
        answer = [ schema ];
      };
      valid = builtins.filter (s: coversDesired s desired) schemaLib;
      ranked = builtins.sort (a: b: a.weight < b.weight) (builtins.map rank valid);
    in
    take n ranked;
in
{
  inherit synthFromOptions synthMinimalOverride importSel;
}
