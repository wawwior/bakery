{ self, ... }:
let
  lib = self.lib;
in
{
  nixosSystems =
    modules:
    {
      inputs',
      self',
      ...
    }:
    {
      nixosConfigurations = builtins.mapAttrs (
        name: modules':
        inputs'.nixpkgs.lib.nixosSystem {
          modules = modules' ++ [
            (
              { pkgs, ... }:
              {
                nixpkgs = self'.nixpkgs;
                networking.hostName = pkgs.lib.mkDefault name;
              }
            )
          ];
        }
      ) (lib.mergeLeft modules);
    };
}
