{ ... }:
rec {

  /**
    Merge two attribute sets recursively, right side trumps left

    # Inputs

    `x`

    : Left attribute set

    `y`

    : Right attribute set (higher precedence for equal keys)

    # Type

    ```
    mergeAttrsRecursive :: AttrSet -> AttrSet -> AttrSet
    ```
  */
  mergeAttrsRecursive =
    x: y:
    x
    // y
    // (builtins.mapAttrs (
      name: right:
      let
        left = x.${name} or null;
      in
      if builtins.isAttrs left && builtins.isAttrs right then
        mergeAttrsRecursive left right
      else if builtins.isList left && builtins.isList right then
        left ++ right
      else
        right
    ) y);

  /**
    Filter an attribute set by removing all attributes for which the given predicate return false.

    # Inputs

    `pred`

    : Predicate taking an attribute name and an attribute value, which returns `true` to include the attribute, or `false` to exclude the attribute.

    `set`

    : The attribute set to filter

    # Type

    ```
    filterAttrs :: (String -> a -> Bool) -> { [String] :: a } -> { [String] :: a }
    ```
  */
  filterAttrs =
    pred: set:
    removeAttrs set (builtins.filter (name: !pred name set.${name}) (builtins.attrNames set));

  /**
    Filter an attribute set recursively by removing all attributes for
    which the given predicate return false.

    # Inputs

    `pred`

    : Predicate taking an attribute name and an attribute value, which returns `true` to include the attribute, or `false` to exclude the attribute.

    `set`

    : The attribute set to be filter

    # Type

    ```
    filterAttrsRecursive :: (String -> Any -> Bool) -> AttrSet -> AttrSet
    ```
  */
  filterAttrsRecursive =
    predicate: set:
    builtins.mapAttrs (
      name: value: if builtins.isAttrs value then filterAttrsRecursive predicate value else value
    ) (filterAttrs predicate set);

  /**
    Turns a list of attribute set into an attribute set with lists for all attributes i.e. 'descend' one level of nesting.

    `list`

    : List of attribute sets to be collected from

    # Type

    ```
    descendAttrs :: [String] -> [AttrSet] -> AttrSet
    ```
  */
  descendAttrs =
    list:
    builtins.listToAttrs (
      map (attr: {
        name = attr;
        value = builtins.filter (value: value != null) (map (value: value.${attr} or null) list);
      }) (builtins.attrNames (builtins.foldl' (acc: set: acc // set) { } list))
    );

  mergeLeft = builtins.foldl' (acc: set: mergeAttrsRecursive acc set) { };
}
