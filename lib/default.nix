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

  defaultDoughs = lib.mergeLeft (
    map (
      path:
      let
        expr = import path;
      in
      if builtins.isFunction expr then expr inputs else expr
    ) (collectFiles ./doughs)
  );

  mkFlake = _: _mkFlake { inputs' = _; };

  _mkFlake =
    args@{ inputs' }:
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
        importList outputs;

      importList =
        expr':
        let
          doughs' = (lib.mergeLeft (map (module: module.bakery or { }) expr')).doughs or { };

          doughs = (if doughs'.disableDefaults or false then { } else defaultDoughs) // doughs';

          collected = lib.filterAttrs (name: value: builtins.hasAttr name doughs) (
            lib.descendAttrs (map (module: module.bakery or { }) expr')
          );

          outputs =
            (
              self':
              (lib.mergeLeft (
                builtins.attrValues (
                  builtins.mapAttrs (
                    name: value:
                    (doughs.${name}) value (
                      args
                      // {
                        inherit self';
                      }
                    )
                  ) collected
                )
              ))
            )
              outputs;
        in
        outputs;

      importExpr' =
        expr':
        if builtins.isPath expr' then
          if builtins.readFileType expr' == "directory" then importDir expr' else importExpr' (import expr')
        else if builtins.isList expr' then
          importList expr'
        else if builtins.isFunction expr' then
          importExpr' (expr' inputs')
        else
          importList [ expr' ];

    in
    importExpr' expr;
}
