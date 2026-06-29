{ ... }:
{
  combine = builtins.foldl' (acc: set: {
    imports = acc.imports ++ [ set ];
  }) { imports = [ ]; };

  resolve = {
    systems = { ... }: module: module;
    users = { ... }: module: module;
  };
}
