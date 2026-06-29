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
          driver = import ./lib/driver.nix inputs;
        in
        (import ./lib inputs)
        // file-tree
        // attrsets
        // driver
        // {
          inherit file-tree attrsets driver;
        };
    };
}
