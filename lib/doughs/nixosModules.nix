inputs@{ ... }:
with inputs.self.lib.attrs;
{
  nixosModules =
    { list, ... }:
    {
      nixosModules = builtins.mapAttrs (name: value: { imports = value; }) (
        collect (builtins.attrNames (builtins.foldl' (acc: set: acc // set) { } list)) list
      );
    };
}
