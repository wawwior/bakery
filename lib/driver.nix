inputs@{ self, ... }:
let
  inherit (self) lib;
in
{

  parseDoughs =
    list:
    let
      doughs = builtins.mapAttrs (name: value: value // { __bakeryType = name; }) (
        lib.mergeLeft (lib.descendAttrs list).doughs
      );
      out = if builtins.hasAttr "doughs" doughs then throw "cannot define dough for doughs" else doughs;
    in
    out;

  parseInstances =
    instancesParts: dough:
    let
      instances = lib.descendAttrs instancesParts;
    in
    builtins.mapAttrs (name: instanceParts: lib.parseInstance instanceParts dough) instances;

  parseInstance =
    instanceParts: dough:
    let
      requires = lib.parseRequires instanceParts dough;
    in
    lib.mergeLeft [
      (lib.parseAttributes instanceParts dough)
      (if requires.kin != [ ] then lib.parseInstance requires.kin dough else { })
      {
        requires = requires.nonKin;
      }
    ];

  parseAttributes =
    instanceParts: dough:
    let
      instance = lib.descendAttrs instanceParts;
    in
    builtins.mapAttrs (name: attributeParts: dough.attributes.${name}.combine attributeParts) (
      removeAttrs instance [
        "requires"
        "__bakeryType"
      ]
    );

  parseRequires =
    instanceParts: dough:
    let
      instance = lib.descendAttrs instanceParts;
      requires = builtins.concatLists (instance.requires or [ ]);
      kinRequires = builtins.filter (value: value.__bakeryType == dough.__bakeryType) requires;
      nonKinRequires = builtins.filter (value: value.__bakeryType != dough.__bakeryType) requires;
      out =
        if
          !((dough.requires or [ ]) == [ ])
          &&
            (builtins.filter (value: !(builtins.elem value.__bakeryType dough.requires)) nonKinRequires) != [ ]
        then
          throw "requires has wrong type"
        else
          {
            kin = kinRequires;
            nonKin = nonKinRequires;
          };
    in
    out;

  parseDynamics =
    list: doughs:
    let
      bakery = lib.descendAttrs list;
    in
    builtins.mapAttrs (name: dynamicParts: lib.parseInstances dynamicParts doughs.${name}) (
      removeAttrs bakery [ "doughs" ]
    );

  parseBakery =
    list:
    let
      doughs = lib.parseDoughs list;
      dynamics = lib.parseDynamics list doughs;
    in
    dynamics
    // {
      inherit doughs;
    };

  enrichTypes =
    bakery:
    builtins.mapAttrs (
      name: instances:
      builtins.mapAttrs (
        _: instance:
        instance // (if builtins.hasAttr name (bakery.doughs or { }) then { __bakeryType = name; } else { })
      ) instances
    ) bakery;

  produceOutputs =
    bakery: inputs':
    lib.mergeLeft (
      builtins.concatLists (
        builtins.attrValues (
          builtins.mapAttrs (
            type: dough:
            builtins.attrValues (
              builtins.mapAttrs (
                name: module:
                (dough.output or (_: { })) {
                  inherit name;
                  module = lib.resolveModule {
                    inherit bakery module inputs';
                    scope = module.__bakeryType;
                    context = removeAttrs module [ "includes" ];
                  };
                }
              ) bakery.${type}
            )
          ) bakery.doughs
        )
      )
    );

  resolveModule =
    {
      bakery,
      module,
      scope,
      context,
    }:
    {
      # TODO: extensible requires
      imports =
        (builtins.attrValues (
          builtins.mapAttrs (
            name: value:
            (bakery.doughs.${module.__bakeryType}.attributes.${name}.resolve.${scope} or (_: _: { })) context
              value
          ) module
        ))
        ++ map (
          required:
          lib.resolveModule {
            inherit bakery scope context;
            module = required;
          }
        ) (module.requires);
    };
}
