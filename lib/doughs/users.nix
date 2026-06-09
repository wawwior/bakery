{ self, ... }:
let
  lib = self.lib;
in
{
  users =
    modules:
    { inputs', ... }:
    { pkgs, ... }:
    {
      users.mutableUsers = false;
    }
    // (lib.mergeLeft (
      builtins.mapAttrs (
        name': module':
        let
          defaultModules = module'.defaultModules or true;
          name = module'.name or name';
          home = module'.home or (if pkgs.stdenv.isLinux then "/home/${name}" else "/Users/${name}");
          modules' = module'.modules or [ ];
        in
        if modules' == [ ] then
          { }
        else
          {
            imports = [
              inputs'.home-manager.nixosModules.home-manager
            ];
            home-manager = {
              extraSpecialArgs = {
                inputs = inputs';
              };
              users.${name} = {
                home = {
                  username = name;
                  homeDirectory = home;
                };
                imports = (if defaultModules then [ ] else [ ]) ++ modules';
              };
            };
          }
          // {
            users.users.${name} = {
              inherit name;
            };

          }
      ) modules
    ));
}
