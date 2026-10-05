# ext/staged.nix — relational expression evaluator with holes [L016]
# Expr: {atom=v} | {ref="name"} | {add=[e1,e2]} | {attrs={k:expr}}
# Holes = fresh vars in atom/ref positions.
ukanren:
let
  inherit (ukanren) isVar;
  inherit (ukanren) walk;

  # wrapAdd a b val: arithmetic relation — solves for unknown when 2 of 3 are ground.
  wrapAdd =
    a: b: val: state:
    let
      a' = walk state.subst a;
      b' = walk state.subst b;
      v' = walk state.subst val;
    in
    if !isVar a' && !isVar b' then
      (ukanren.eq (a' + b') val) state
    else if !isVar a' && !isVar v' then
      (ukanren.eq (v' - a') b) state
    else if !isVar b' && !isVar v' then
      (ukanren.eq (v' - b') a) state
    else
      null;

  evalExpr =
    expr: env: val:
    if builtins.isAttrs expr && expr ? atom then
      ukanren.eq expr.atom val
    else if builtins.isAttrs expr && expr ? ref then
      state:
      let
        name = walk state.subst expr.ref;
        envVal = if isVar name then null else env.${name} or null;
      in
      if envVal == null then null else (ukanren.eq envVal val) state
    else if builtins.isAttrs expr && expr ? add then
      let
        e1 = builtins.elemAt expr.add 0;
        e2 = builtins.elemAt expr.add 1;
      in
      ukanren.fresh (
        a:
        ukanren.fresh (
          b: ukanren.conj (evalExpr e1 env a) (ukanren.conj (evalExpr e2 env b) (wrapAdd a b val))
        )
      )
    else if builtins.isAttrs expr && expr ? attrs then
      let
        fields = builtins.attrNames expr.attrs;
        wrap =
          f: inner: acc:
          ukanren.fresh (v: ukanren.conj (evalExpr expr.attrs.${f} env v) (inner (acc // { ${f} = v; })));
        base = acc: ukanren.eq val acc;
        goal = builtins.foldl' (inner: f: wrap f inner) base fields;
      in
      goal { }
    else
      ukanren.fail;
in
{
  inherit evalExpr;
}
