inputs@{ ... }:
with inputs.self.lib.attrsets;
{
  nixosModules =
    { list, ... }:
    {
      nixosModules = builtins.mapAttrs (name: value: { imports = value; }) (descend list);
    };
}
