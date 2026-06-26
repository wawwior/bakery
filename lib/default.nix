inputs@{ self, ... }:
let
  lib = self.lib;
in
rec {

  collectFiles =
    path:
    lib.collectPaths path (
      lib.pruneFileTree (
        lib.filterFileTree (file: (builtins.match "[^\._].*\.nix" file) != null) (
          dir: (builtins.match "[^\._].*" dir) != null
        ) (lib.scanDirectory path)
      )
    );

  mkFlake = _: _mkFlake { inputs' = _; };

  _mkFlake =
    { inputs' }:
    expr:
    let
      importDir =
        path:
        let
          collected = collectFiles path;

          outputs = map (
            path:
            let
              module = import path;
            in
            if builtins.isFunction module then module inputs' else module
          ) collected;
        in
        importList outputs;

      importList =
        expr':
        let

          bakery' = (lib.descendAttrs (map (value: value.bakery or { }) expr'));

          modules = lib.mergeLeft (
            map (
              value:
              (builtins.mapAttrs (
                name: module:
                {
                  requires = module.requires or [ ];
                }
                // (
                  if (module.nixos or { }) == { } then
                    { }
                  else
                    {
                      nixos = {
                        imports = [ module.nixos or { } ];
                      };
                    }
                )
                // (
                  if (module.home or { }) == { } then
                    { }
                  else
                    {
                      home = {
                        imports = [ module.home or { } ];
                      };
                    }
                )
              ) value)
            ) bakery'.modules
          );

          nixpkgs = lib.mergeLeft bakery'.nixpkgs;

          # TODO: composability
          systems = lib.mergeLeft bakery'.systems;

          users = lib.mergeLeft bakery'.users;

        in
        {

          bakery = {
            inherit modules systems users;
          };

          nixosConfigurations = builtins.mapAttrs (
            name: system:
            let

              usernames = builtins.attrValues (builtins.mapAttrs (name: value: value.name) system.users);

              resolveUser =
                user:
                (builtins.concatLists (map resolveUserModule (user.modules or [ ])))
                ++ [
                  (
                    { pkgs, ... }:
                    let
                      username = user.name;
                      homeDirectory =
                        user.homeDirectory or (if pkgs.stdenv.isLinux then "/home/${username}" else "/Users/${username}");
                    in
                    (
                      if (user.modules or [ ]) == [ ] then
                        { }
                      else
                        {
                          imports = [
                            inputs'.home-manager.nixosModules.home-manager
                          ];
                          home-manager.users.${username} = {
                            home = {
                              inherit username homeDirectory;
                            };
                          };
                        }
                    )
                    // {
                      users.mutableUsers = false;
                      users.groups.${username} = { };
                      users.users.${username} = {
                        name = username;
                        home = homeDirectory;
                        group = username;
                      };
                    }
                  )

                ];

              resolveUserModule =
                username: module:
                (builtins.concatLists (map resolveUserModule module.requires or [ ]))
                ++ [
                  (module.nixos or { })
                  (
                    if (module.home or { }) == { } then
                      { }
                    else
                      {
                        home-manager.users.${username}.imports = [ module.home ];
                      }
                  )
                ];

              resolveModule =
                module:
                (builtins.concatLists (map resolveModule module.requires or [ ]))
                ++ [
                  (module.nixos or { })
                  (
                    if (module.home or { }) == { } then
                      { }
                    else
                      (
                        { ... }:
                        {
                          imports = [
                            inputs'.home-manager.nixosModules.home-manager
                          ];
                          home-manager.users = builtins.listToAttrs (
                            map (name: {
                              inherit name;
                              value = {
                                imports = [
                                  module.home
                                ];
                              };
                            }) usernames
                          );
                        }
                      )
                  )
                ];
            in
            inputs'.nixpkgs.lib.nixosSystem {
              modules =
                (builtins.concatLists (map resolveModule system.modules))
                ++ (builtins.concatLists (map resolveUser system.users))
                ++ [
                  {
                    inherit nixpkgs;
                  }
                ];
            }
          ) systems;
        };

      importExpr' =
        expr':
        if builtins.isPath expr' then
          if builtins.readFileType expr' == "directory" then importDir expr' else importExpr' (import expr')
        else if builtins.isList expr' then
          importList expr'
        else if builtins.isFunction expr' then
          importExpr' (expr' inputs')
        else
          importList [ expr' ];

    in
    importExpr' expr;
}
