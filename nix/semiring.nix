# ext/semiring.nix — weighted search (Tropical semiring) [L015]
# weight w goal: adds w to each answer's accumulated weight.
# wrun n goalFn: collects answers sorted by ascending weight.
ukanren:
let
  mapStream =
    f: s:
    if s == null then
      null
    else
      {
        head = f s.head;
        tail = mapStream f s.tail;
      };

  addWeight = w: s: s // { weight = (s.weight or 0) + w; };

  # dedup by key function (keeps first occurrence)
  dedup =
    keyFn: lst:
    let
      go =
        seen: l:
        if l == [ ] then
          [ ]
        else
          let
            h = builtins.head l;
            k = keyFn h;
          in
          if builtins.elem k seen then
            go seen (builtins.tail l)
          else
            [ h ] ++ go (seen ++ [ k ]) (builtins.tail l);
    in
    go [ ] lst;

  # stable sort: builtins.sort is not stable, but equal-weight answers
  # preserve relative stream order via index-tagged sort
  stableSort =
    lst:
    let
      tagged = builtins.genList (i: {
        inherit i;
        v = builtins.elemAt lst i;
      }) (builtins.length lst);
      sorted = builtins.sort (
        a: b: if a.v.weight != b.v.weight then a.v.weight < b.v.weight else a.i < b.i
      ) tagged;
    in
    builtins.map (x: x.v) sorted;
  prepare =
    n: goalFn:
    let
      initial = {
        subst = { };
        counter = 0;
        weight = 0;
      };
      raw = ukanren.streamTake (n * 100) (ukanren.fresh goalFn initial);
      unique = dedup (s: ukanren.reify s.subst (ukanren.mkVar "v0")) raw;
      sorted = stableSort unique;
      count = builtins.length sorted;
      take = if count <= n then count else n;
    in
    builtins.genList (i: builtins.elemAt sorted i) take;
in
{
  # weight w goal: wraps goal, accumulates w onto each answer's weight
  weight =
    w: goal: state:
    mapStream (addWeight w) (goal state);

  # wrun n goalFn: top-n answers sorted by ascending weight
  wrun = n: goalFn: builtins.map (s: ukanren.reify s.subst (ukanren.mkVar "v0")) (prepare n goalFn);

  # wrunFull n goalFn: like wrun but returns [{ answer; weight }]
  wrunFull =
    n: goalFn:
    builtins.map (s: {
      answer = ukanren.reify s.subst (ukanren.mkVar "v0");
      weight = s.weight or 0;
    }) (prepare n goalFn);
}
