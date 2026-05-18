inputs@{ ... }:
with inputs.self.lib.attrs;
{
  diskoConfigurations =
    { list, inputs', ... }:
    {
      diskoConfigurations = builtins.mapAttrs (_name: _config: {
        imports = [ inputs'.disko.nixosModules.default ];
        disko.devices = _config;
      }) (builtins.foldl' (acc: set: mergeRecursive acc set) { } list);
    };
}
