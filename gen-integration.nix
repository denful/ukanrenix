# gen-integration.nix — ukanrenix + gen ecosystem integrations
# Usage: import ./gen-integration.nix { genMerge; genSelect; genTypes; }
# Returns: ukanren attrset extended with gen-native synthesis functions
{ genMerge, genSelect, genTypes, genScope }:
let
  ukanren     = import ./. {};
  typesChr    = import ./gen/gen-types-chr.nix      ukanren genTypes;
  schemaSynth = import ./gen/gen-schema-synth.nix   ukanren genMerge genTypes;
  selectSynth = import ./gen/gen-select-synth.nix   ukanren genSelect;
  mergeBwd    = import ./gen/gen-merge-backward.nix ukanren genMerge;
  scopeSynth  = import ./gen/gen-scope-synth.nix    ukanren genScope;
in
ukanren // typesChr // schemaSynth // selectSynth // mergeBwd // scopeSynth
