{ self, ... }:
let
  lib = self.lib;
in
rec {

  /**
    Scan a directory recursively and build a file tree.
    A file tree is an attrset where nested sets represent directories and empty string values represent files.

    # Inputs

    `path`

    : The path to scan

    # Type

    scanDirectory :: Path -> AttrSet
  */
  scanDirectory =
    path:
    builtins.mapAttrs (
      name: type: if type == "directory" then scanDirectory (path + "/${name}") else ""
    ) (builtins.readDir path);

  /**
    Prune a file tree built by `scanDirectory`, that is, remove all directories that don't contain files down the line.

    # Inputs

    `set`

    : The file tree

    # Type

    pruneFileTree :: AttrSet -> AttrSet
  */
  pruneFileTree =
    set:
    lib.filterAttrs (name: value: value != { }) (
      builtins.mapAttrs (name: value: if builtins.isAttrs value then pruneFileTree value else value) set
    );

  /**
    Filter files and directories of a file tree according to predicates.

    # Inputs

    `leafPredicate`

    : Predicate taking a file name, which returns `true` to include the file, or `false` to exclude the file.

    `nodePredicate`

    : Predicate taking a directory name, which returns `true` to include the directory, or `false` to exclude the directory.

    # Type

    filterFileTree :: (String -> Bool) -> (String -> Bool) -> AttrSet -> AttrSet
  */
  filterFileTree =
    leafPredicate: nodePredicate:
    lib.filterAttrsRecursive (
      name: value: if value == "" then leafPredicate name else nodePredicate name
    );

  /**
    Collects all paths of a file tree in a list.

    # Inputs

    `parent`

    : The root of the file tree, prepended to all paths

    `tree`

    : The file tree to be collected

    # Type

    collectPaths :: Path -> AttrSet -> [Path]
  */
  collectPaths =
    parent: tree:
    builtins.concatMap (
      name:
      if tree.${name} == "" then
        [ (parent + "/${name}") ]
      else
        collectPaths (parent + "/${name}") tree.${name}
    ) (builtins.attrNames tree);
}
