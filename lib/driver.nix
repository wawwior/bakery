{ self, ... }:
let
  inherit (self) lib;
in
{

  parseRecipes =
    list:
    let
      recipes = builtins.mapAttrs (name: value: value // { __bakeryType = name; }) (
        lib.mergeLeft (lib.descendAttrs list).recipes
      );
      out =
        if builtins.hasAttr "recipes" recipes || builtins.hasAttr "self" recipes then
          throw "cannot define recipe for recipes or self"
        else
          recipes;
    in
    out;

  parseInstances =
    instancesParts: recipe:
    let
      instances = lib.descendAttrs instancesParts;
    in
    builtins.mapAttrs (name: instanceParts: lib.parseInstance instanceParts recipe) instances;

  parseInstance =
    instanceParts: recipe:
    let
      requires = lib.parseRequires instanceParts recipe;
    in
    lib.mergeLeft [
      (lib.parseAttributes instanceParts recipe)
      (if requires.kin != [ ] then lib.parseInstance requires.kin recipe else { })
      {
        requires = requires.nonKin;
      }
    ];

  parseAttributes =
    instanceParts: recipe:
    let
      instance = lib.descendAttrs instanceParts;
    in
    builtins.mapAttrs (name: attributeParts: recipe.attributes.${name}.combine attributeParts) (
      removeAttrs instance [
        "requires"
        "__bakeryType"
      ]
    );

  parseRequires =
    instanceParts: recipe:
    let
      instance = lib.descendAttrs instanceParts;
      requires = builtins.concatLists (instance.requires or [ ]);
      kinRequires = builtins.filter (value: value.__bakeryType == recipe.__bakeryType) requires;
      nonKinRequires = builtins.filter (value: value.__bakeryType != recipe.__bakeryType) requires;
      out =
        if
          !((recipe.requires or [ ]) == [ ])
          &&
            (builtins.filter (value: !(builtins.elem value.__bakeryType recipe.requires)) nonKinRequires) != [ ]
        then
          throw "requires has wrong type"
        else
          {
            kin = kinRequires;
            nonKin = nonKinRequires;
          };
    in
    out;

  parseDoughs =
    list: recipes:
    let
      bakery = lib.descendAttrs list;
    in
    builtins.mapAttrs (name: doughParts: lib.parseInstances doughParts recipes.${name}) (
      removeAttrs bakery [ "recipes" ]
    );

  parseBakery =
    list:
    let
      recipes = lib.parseRecipes list;
      doughs = lib.parseDoughs list recipes;
    in
    doughs
    // {
      inherit recipes;
    };

  enrichTypes =
    bakery:
    builtins.mapAttrs (
      name: instances:
      builtins.mapAttrs (
        _: instance:
        instance
        // (if builtins.hasAttr name (bakery.recipes or { }) then { __bakeryType = name; } else { })
      ) instances
    ) bakery;

  produceOutputs =
    bakery: inputs':
    lib.mergeLeft (
      builtins.concatLists (
        builtins.attrValues (
          builtins.mapAttrs (
            type: recipe:
            builtins.attrValues (
              builtins.mapAttrs (
                name: module:
                (recipe.output or (_: { })) {
                  inherit name inputs';
                  module = lib.resolveModule {
                    inherit bakery module;
                    scope = module.__bakeryType;
                    context = removeAttrs module [ "requires" ];
                  };
                }
              ) bakery.${type}
            )
          ) bakery.recipes
        )
      )
    );

  resolveModule =
    args@{
      module,
      ...
    }:
    module
    // {
      requires = lib.resolveRequires args;
    };

  resolveRequires =
    {
      bakery,
      module,
      scope,
      context,
    }:
    map (required: {
      # TODO: extensible requires
      imports =
        (builtins.attrValues (
          builtins.mapAttrs (
            name: value:
            let
              scope' = if required.__bakeryType == scope then "self" else scope;
            in
            (bakery.recipes.${required.__bakeryType}.attributes.${name}.resolve.${scope'} or (_: _: { }))
              context
              value
          ) required
        ))
        ++ (lib.resolveRequires {
          inherit bakery scope context;
          module = required;
        });
    }) (module.requires);
}
