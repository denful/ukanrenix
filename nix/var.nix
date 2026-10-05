ukanren: {
  mkVar = id: {
    __var = true;
    inherit id;
  };
  isVar = x: builtins.isAttrs x && x.__var or false;
  walk =
    subst: term:
    if !(ukanren.isVar term) then
      term
    else
      let
        bound = subst.${term.id} or null;
      in
      if bound == null then term else ukanren.walk subst bound;
}
