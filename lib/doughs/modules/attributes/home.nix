{ ... }:
{
  combine = builtins.foldl' (acc: set: {
    imports = acc.imports ++ [ set ];
  }) { imports = [ ]; };

  resolve = {
    systems =
      { ... }:
      module:
      { inputs', config, ... }:
      {
        imports = [ inputs'.home-manager.nixosModules.home-manager ];
        home-manager.users = builtins.mapAttrs (name: value: {
          imports = [ module ];
        }) config.home-manager.users;
      };
    users =
      { name, ... }:
      module:
      { inputs', ... }:
      {
        imports = [ inputs'.home-manager.nixosModules.home-manager ];
        home-manager.users.${name}.imports = [ module ];
      };
  };
}
