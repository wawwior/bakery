inputs@{ self, ... }:
let
  lib = self.lib;
in
rec {

  collectFiles =
    path:
    lib.collectPaths path (
      lib.pruneFileTree (
        lib.filterFileTree (file: (builtins.match "[^\._].*\.nix" file) != null) (
          dir: (builtins.match "[^\._].*" dir) != null
        ) (lib.scanDirectory path)
      )
    );

  mkFlake = _: _mkFlake { inputs' = _; };

  _mkFlake =
    { inputs' }:
    expr:
    let
      importDir =
        path:
        let
          collected = collectFiles path;

          outputs = map (
            path:
            let
              module = import path;
            in
            if builtins.isFunction module then module inputs' else module
          ) collected;
        in
        outputs;

      importExpr' =
        expr':
        if builtins.isPath expr' then
          if builtins.readFileType expr' == "directory" then importDir expr' else importExpr' (import expr')
        else if builtins.isFunction expr' then
          importExpr' (expr' inputs')
        else
          throw "";

    in
    importExpr' expr;
}
