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
        name: module':
        let
          hostName = module'.hostName or name;
          modules' = module'.modules or [ ];
        in
        inputs'.nixpkgs.lib.nixosSystem {
          modules = modules' ++ [
            (
              { ... }:
              {
                nixpkgs = self'.nixpkgs;
                networking = { inherit hostName; };
              }
            )
          ];
        }
      ) (lib.mergeLeft modules);
    };
}
