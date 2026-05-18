{ self, ... }:
with self.lib;
rec {

  # recursively scan a directory and build a file tree
  scan =
    path:
    builtins.mapAttrs (name: type: if type == "directory" then scan (path + "/${name}") else "") (
      builtins.readDir path
    );

  # recursively prune all file tree branches without leaf nodes (files)
  prune =
    set:
    attrs.filter (name: value: value != { }) (
      builtins.mapAttrs (name: value: if builtins.isAttrs value then prune value else value) set
    );

  # recursively filter nodes and leaves according to predicates
  filter =
    leafPredicate: nodePredicate:
    attrs.filterRecursive (name: value: if value == "" then leafPredicate name else nodePredicate name);

  # collect all paths of a tree in a list
  collect =
    parent: tree:
    builtins.concatMap (
      name:
      if tree.${name} == "" then [ (parent + "/${name}") ] else collect (parent + "/${name}") tree.${name}
    ) (builtins.attrNames tree);
}
