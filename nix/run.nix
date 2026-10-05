ukanren: {
  reify =
    subst: term:
    let
      t = ukanren.walk subst term;
    in
    if ukanren.isVar t then
      t
    else if builtins.isList t then
      builtins.map (ukanren.reify subst) t
    else if builtins.isAttrs t then
      builtins.mapAttrs (_: v: ukanren.reify subst v) t
    else
      t;

  # query var is always v0 (fresh creates it first from counter=0) [L010]
  run =
    n: goalFn:
    let
      initial = {
        subst = { };
        counter = 0;
      };
      stream = ukanren.fresh goalFn initial;
      answers = ukanren.streamTake n stream;
    in
    builtins.map (state: ukanren.reify state.subst (ukanren.mkVar "v0")) answers;
}
