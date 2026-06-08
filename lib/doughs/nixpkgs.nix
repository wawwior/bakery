{ self, ... }:
let
  lib = self.lib;
in
{
  nixpkgs =
    modules:
    { ... }:
    {
      nixpkgs = lib.mergeLeft modules;
    };
}
