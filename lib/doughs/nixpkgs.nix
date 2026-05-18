inputs@{ ... }:
with inputs.self.lib.attrs;
{
  nixpkgs =
    { list, ... }:
    {
      nixpkgs = builtins.foldl' (acc: set: mergeRecursive acc set) { } list;
    };
}
