# gen-types-chr.nix — CHR type guards via gen-types verify protocol
# ukanren: genTypes: → { typeGoal intGoal strGoal boolGoal listOfGoal nullOrGoal }
#
# typeGoal checker val: deferred until val is ground, then verify.
# If verify returns null → pass. Non-null → prune branch (fail).
ukanren: genTypes:
let
  inherit (ukanren) isVar reify;
  succeed = s: {
    head = s;
    tail = null;
  };
  fail = _: null;

  typeGoal =
    checker: val: state:
    let
      tv = reify state.subst val;
    in
    if isVar tv then
      succeed state
    else if checker.verify tv == null then
      succeed state
    else
      fail state;

  intGoal = typeGoal genTypes.int;
  strGoal = typeGoal genTypes.str;
  boolGoal = typeGoal genTypes.bool;
  listOfGoal = elemChecker: typeGoal (genTypes.listOf elemChecker);
  nullOrGoal = baseChecker: typeGoal (genTypes.nullOr baseChecker);
in
{
  inherit
    typeGoal
    intGoal
    strGoal
    boolGoal
    listOfGoal
    nullOrGoal
    ;
}
