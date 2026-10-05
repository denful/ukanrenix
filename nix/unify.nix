ukanren: {
  unify =
    u: v: subst:
    let
      u' = ukanren.walk subst u;
      v' = ukanren.walk subst v;
    in
    if ukanren.isVar u' && ukanren.isVar v' && u'.id == v'.id then
      subst
    else if ukanren.isVar u' then
      subst // { ${u'.id} = v'; }
    else if ukanren.isVar v' then
      subst // { ${v'.id} = u'; }
    else if builtins.isList u' && builtins.isList v' then
      if builtins.length u' != builtins.length v' then
        null
      else
        builtins.foldl' (
          s: i: if s == null then null else ukanren.unify (builtins.elemAt u' i) (builtins.elemAt v' i) s
        ) subst (builtins.genList (i: i) (builtins.length u'))
    else if builtins.isAttrs u' && builtins.isAttrs v' then
      let
        uKeys = builtins.attrNames u';
        vKeys = builtins.attrNames v';
      in
      if uKeys != vKeys then
        null
      else
        builtins.foldl' (s: k: if s == null then null else ukanren.unify u'.${k} v'.${k} s) subst uKeys
    else if u' == v' then
      subst
    else
      null;
}
