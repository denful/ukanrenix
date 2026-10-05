help:
  just -l

fmt *args:
  deadnix --edit
  statix fix
  nixfmt **/*.nix {{args}}

test suite="all" *args:
  nix-unit --expr 'let x = import ./tests.nix; in if "{{suite}}" == "all" then x else x.{{suite}}' {{args}}

ci:
  deadnix --fail
  statix check
  just fmt --ci
  just test
