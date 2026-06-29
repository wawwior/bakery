inputs@{ self, ... }:
let
  inherit (self) lib;
in
{

  collectDoughs = bakery: lib.mergeLeft (map (value: value.doughs or { }) bakery);

  enrichTypes =
    bakery:
    let
      doughs = lib.collectDoughs bakery;
    in
    builtins.mapAttrs (
      name: value: value // (if builtins.hasAttr name doughs then { __bakeryType = name; } else { })
    ) bakery;

  resolveIncludes = bakery: module: scope: {
    imports = builtins.concatLists (
      map (
        include:
        builtins.attrValues (
          builtins.mapAttrs (
            name: value:
            ((lib.collectDoughs bakery).${include.__bakeryType}.attributes.${name}.resolve.${scope} or (_: { }))
              value
          ) include
        )
        ++ [
          (lib.resolveIncludes bakery include scope)
        ]
      ) (module.includes or [ ])
    );
  };
}
