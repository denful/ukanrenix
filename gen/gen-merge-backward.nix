# gen-merge-backward.nix — evalModuleo wrapping gen-merge.evalModuleTree
# ukanren: genMerge: → { evalModuleo synthFromModules }
#
# evalModuleo modules q
#   Forward: ground modules → q unified with gen-merge merged config
#   Backward: q partially ground → constrain merged result
#
# synthFromModules moduleLib desired n
#   Finds n smallest subsets of moduleLib whose merged config covers desired.
#   Returns: [{weight; answer; config}] sorted by subset size
ukanren: genMerge:
let
  take =
    n: list:
    if n == 0 || list == [ ] then
      [ ]
    else
      [ (builtins.head list) ] ++ take (n - 1) (builtins.tail list);

  evalModuleo =
    modules: q: state:
    let
      tree = genMerge.evalModuleTree { inherit modules; };
      merged = tree.config;
      newSubst = ukanren.unify merged q state.subst;
    in
    if newSubst == null then
      null
    else
      {
        head = state // {
          subst = newSubst;
        };
        tail = null;
      };

  covers =
    desired: config:
    builtins.all (f: config ? ${f} && config.${f} == desired.${f}) (builtins.attrNames desired);

  # All non-empty subsets, smallest first
  subsets =
    lib:
    let
      go =
        ms: acc:
        if ms == [ ] then
          acc
        else
          let
            m = builtins.head ms;
            rest = builtins.tail ms;
            withM = builtins.map (s: s ++ [ m ]) acc;
          in
          go rest (acc ++ withM);
    in
    builtins.sort (a: b: builtins.length a < builtins.length b) (
      builtins.filter (s: s != [ ]) (go lib [ [ ] ])
    );

  synthFromModules =
    moduleLib: desired: n:
    let
      valid = builtins.filter (
        subset:
        let
          cfg = (genMerge.evalModuleTree { modules = subset; }).config;
        in
        covers desired cfg
      ) (subsets moduleLib);
    in
    take n (
      builtins.map (s: {
        weight = builtins.length s;
        answer = s;
        inherit ((genMerge.evalModuleTree { modules = s; })) config;
      }) valid
    );
in
{
  inherit evalModuleo synthFromModules;
}
