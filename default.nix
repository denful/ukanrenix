# ukanrenix — pure-Nix μKanren. flake-free entry point.
# import ./. {}  →  ukanren attrset
_:
let
  readDirImports =
    dir:
    let
      files = builtins.readDir dir;
      fileList = builtins.filter (name: builtins.match ".*\\.nix$" name != null) (
        builtins.attrNames files
      );
      imports = builtins.map (name: import (dir + "/${name}") ukanren) fileList;
    in
    builtins.foldl' (acc: val: acc // val) { } imports;

  ukanren = readDirImports ./nix;
in
ukanren
