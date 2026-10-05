# ext/chr.nix — CHR constraint handling rules [L013]
# constrain: record predicate in state. chrRun: filter stream by predicates.
# Core goals preserve constraints via state // { ... } pass-through.
ukanren:
let
  # skip stream entries where predicate fails
  filterStream =
    pred: stream:
    if stream == null then
      null
    else if pred stream.head then
      {
        inherit (stream) head;
        tail = filterStream pred stream.tail;
      }
    else
      filterStream pred stream.tail;

  constrain =
    pred: state:
    let
      cs = state.constraints or [ ];
    in
    {
      head = state // {
        constraints = cs ++ [ pred ];
      };
      tail = null;
    };

  checkAll = state: builtins.all (p: p state) (state.constraints or [ ]);
in
{
  inherit constrain;

  # chrRun replaces ukanren.run when using constraints
  chrRun =
    n: goalFn:
    let
      initial = {
        subst = { };
        counter = 0;
        constraints = [ ];
      };
      stream = ukanren.fresh goalFn initial;
      answers = ukanren.streamTake n (filterStream checkAll stream);
    in
    builtins.map (s: ukanren.reify s.subst (ukanren.mkVar "v0")) answers;

  # typeOf var "int"|"string"|"bool"|"list"|"set"|"float"|"null"
  # deferred while var is unbound; checked when bound
  typeOf =
    var: expected:
    constrain (
      state:
      let
        v = ukanren.reify state.subst var;
      in
      ukanren.isVar v || builtins.typeOf v == expected
    );

  # diseq a b — a ≠ b (deferred while either unbound)
  diseq =
    a: b:
    constrain (
      state:
      let
        a' = ukanren.reify state.subst a;
        b' = ukanren.reify state.subst b;
      in
      ukanren.isVar a' || ukanren.isVar b' || a' != b'
    );
}
