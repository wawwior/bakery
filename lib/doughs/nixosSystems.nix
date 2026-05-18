inputs@{ ... }:
with inputs.self.lib.attrs;
{
  nixosSystems =
    {
      inputs',
      self',
      list,
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
      ) (builtins.foldl' (acc: set: mergeRecursive acc set) { } list);
    };
}
