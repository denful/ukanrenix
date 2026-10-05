{
  pkgs ? import <nixpkgs> { },
  ...
}:
pkgs.mkShell {
  buildInputs = [
    pkgs.nix-unit
    pkgs.nixfmt
    pkgs.just
    pkgs.deadnix
    pkgs.statix
    pkgs.dolt
    pkgs.bun
    pkgs.pnpm
  ];
}
