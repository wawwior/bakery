{ ... }:
rec {

  mergeRecursive =
    lhs: rhs:
    lhs
    // rhs
    // (builtins.mapAttrs (
      name: right:
      let
        left = lhs.${name} or null;
      in
      if builtins.isAttrs left && builtins.isAttrs right then
        mergeRecursive left right
      else if builtins.isList left && builtins.isList right then
        left ++ right
      else
        right
    ) rhs);

  filter =
    predicate: set:
    removeAttrs set (builtins.filter (name: !predicate name set.${name}) (builtins.attrNames set));

  filterRecursive =
    predicate: set:
    builtins.mapAttrs (
      name: value: if builtins.isAttrs value then filterRecursive predicate value else value
    ) (filter predicate set);

  collect =
    attrs: list:
    builtins.listToAttrs (
      map (attr: {
        name = attr;
        value = builtins.filter (value: value != null) (map (value: value.${attr} or null) list);
      }) attrs
    );

  fold = builtins.foldl' (acc: set: acc // set) { };
}
