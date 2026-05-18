{

  description = "unified configs";

  inputs = {
  };

  outputs =
    { ... }:
    {

      lib = {
        mkFlake =
          _nixpkgs: _module:
          let
            module = _module;
          in
          if builtins.hasAttr "bakery" module then
            (
              let
                _nixpkgsConfig =
                  if builtins.hasAttr "nixpkgsConfig" module.bakery then module.bakery.nixpkgsConfig else { };

                _nixosSystems =
                  if builtins.hasAttr "nixosSystems" module.bakery then module.bakery.nixosSystems else { };

                _nixosModules =
                  if builtins.hasAttr "nixosModules" module.bakery then module.bakery.nixosModules else { };
              in
              {

                nixosConfigurations = builtins.mapAttrs (
                  _name: _modules:
                  _nixpkgs.lib.nixosSystem {
                    modules = _modules ++ [
                      (
                        { pkgs, ... }:
                        {
                          _module.args.hostName = _name;

                          nixpkgs.config = _nixpkgsConfig;

                          networking.hostName = pkgs.lib.mkDefault _name;
                        }
                      )
                    ];
                  }
                ) _nixosSystems;

                nixosModules = _nixosModules;

              }
            )
          else
            { };
      };
    };
}
