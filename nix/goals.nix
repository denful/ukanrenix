ukanren: {
  succeed = state: {
    head = state;
    tail = null;
  };
  fail = _: null;

  eq =
    u: v: state:
    let
      s = ukanren.unify u v state.subst;
    in
    if s == null then
      null
    else
      {
        head = state // {
          subst = s;
        };
        tail = null;
      };

  fresh =
    f: state:
    let
      var = ukanren.mkVar "v${toString state.counter}";
      state' = state // {
        counter = state.counter + 1;
      };
    in
    (f var) state';

  conj =
    g1: g2: state:
    ukanren.bind (g1 state) g2;

  # infinite interleaved stream — lazy via Nix thunks [L007]
  disj =
    g1: g2: state:
    ukanren.mplus (g1 state) (ukanren.disj g2 g1 state);
}
