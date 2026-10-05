# ext/bank.nix — memoized bottom-up enumeration [L014]
# defBank: evaluate relation once against canonical vars, cache answers.
# pruneBy: dedup list by key function.
ukanren:
let
  # canonical vars use "c" prefix — no conflict with query vars "v"
  mkCanonVars = n: builtins.genList (i: ukanren.mkVar "c${toString i}") n;

  # prune canonical stream to unique answers by reified canonical-var tuple
  pruneCanon =
    cvars: stream:
    let
      key = ans: builtins.map (cv: ukanren.reify ans.subst cv) cvars;
      raw = ukanren.streamTake 1000 stream;
      go =
        seen: lst:
        if lst == [ ] then
          [ ]
        else
          let
            h = builtins.head lst;
            k = key h;
          in
          if builtins.elem k seen then
            go seen (builtins.tail lst)
          else
            [ h ] ++ go (seen ++ [ k ]) (builtins.tail lst);
    in
    go [ ] raw;

  # match actual args against one canonical answer.
  # merges canonical subst into current subst, then unifies each arg with its canon var.
  matchOne =
    cvars: args: state: canonAns:
    let
      # merge: canonical bindings added first; current bindings shadow if conflict (none expected)
      merged = canonAns.subst // state.subst;
      s = builtins.foldl' (
        acc: i:
        if acc == null then null else ukanren.unify (builtins.elemAt args i) (builtins.elemAt cvars i) acc
      ) merged (builtins.genList (i: i) (builtins.length cvars));
    in
    if s == null then null else state // { subst = s; };

  # convert list of states to a stream (head-first order)
  rev = builtins.foldl' (acc: h: [ h ] ++ acc) [ ];
  listToStream =
    lst:
    builtins.foldl' (acc: h: {
      head = h;
      tail = acc;
    }) null (rev lst);
in
{
  # defBank n body : ([term] -> goal)
  # body : [var] -> goal — called ONCE with canonical vars
  defBank =
    n: body:
    let
      cvars = mkCanonVars n;
      cstate = {
        subst = { };
        counter = n; # counter starts at n to avoid name clash with canon vars
      };
      canonAnswers = pruneCanon cvars ((body cvars) cstate);
    in
    args: state:
    let
      matched = builtins.filter (x: x != null) (
        builtins.map (canonAns: matchOne cvars args state canonAns) canonAnswers
      );
    in
    listToStream matched;

  # pruneBy keyFn list : [a] -> [a]  (keeps first occurrence of each key)
  pruneBy =
    keyFn:
    let
      go =
        seen: lst:
        if lst == [ ] then
          [ ]
        else
          let
            h = builtins.head lst;
            k = keyFn h;
          in
          if builtins.elem k seen then
            go seen (builtins.tail lst)
          else
            [ h ] ++ go (seen ++ [ k ]) (builtins.tail lst);
    in
    go [ ];
}
