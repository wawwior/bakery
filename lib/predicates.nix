{ ... }:
rec {

  _not = predicate: path: !(predicate path);
  _and =
    predA: predB: path:
    (predA path) && (predB path);
  _or =
    predA: predB: path:
    (predA path) || (predB path);

  startsWith = substring: path: builtins.match "${substring}.*" path != null;
  endsWith = substring: path: builtins.match ".*${substring}" path != null;
  isNixFile = endsWith "\\.nix";
  isDotFile = startsWith "\\.";
}
