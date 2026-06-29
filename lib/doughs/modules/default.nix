inputs@{ self, ... }:
let
  inherit (self) lib;
in
{
  output =
    {
      name,
      module,
    }:
    { };

  includes = {
    types = [ "modules" ];
    combineInto = true;
  };

  attributes = {
    nixos = import ./attributes/nixos.nix inputs;
    home = import ./attributes/home.nix inputs;
  };
}
