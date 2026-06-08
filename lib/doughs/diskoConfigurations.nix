{ self, ... }:
let
  lib = self.lib;
in
{
  diskoConfigurations =
    modules:
    { inputs', ... }:
    {
      diskoConfigurations = builtins.mapAttrs (_name: _config: {
        imports = [ inputs'.disko.nixosModules.default ];
        disko.devices = _config;
      }) (lib.mergeLeft modules);
    };
}
