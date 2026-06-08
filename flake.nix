{

  description = "unified configs";

  inputs = { };

  outputs =
    inputs@{ ... }:
    {
      lib =
        let
          file-tree = import ./lib/file-tree.nix inputs;
          attrsets = import ./lib/attrsets.nix inputs;
        in
        (import ./lib inputs)
        // file-tree
        // attrsets
        // {
          inherit file-tree attrsets;
        };
    };
}
