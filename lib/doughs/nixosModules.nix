{ self, ... }:
let
  lib = self.lib;
in
{
  nixosModules =
    modules:
    { ... }:
    {
      nixosModules = builtins.mapAttrs (name: value: { imports = value; }) (lib.descendAttrs modules);
    };
}
