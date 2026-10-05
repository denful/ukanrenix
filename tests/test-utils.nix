ukanren: {
  # run goal, reify first answer or null
  firstAnswer = goal: builtins.head (ukanren.run 1 goal);

  # run goal, get all N answers
  answers = n: goal: ukanren.run n goal;

  # assert goal succeeds (at least 1 answer)
  succeeds = goal: builtins.length (ukanren.run 1 goal) > 0;

  # assert goal fails (0 answers)
  fails = goal: ukanren.run 1 goal == [ ];
}
