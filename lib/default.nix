inputs@{ ... }:
rec {

  file-tree = import ./file-tree.nix inputs;
  predicates = import ./predicates.nix inputs;
  attrs = import ./attrs.nix inputs;

  collectFiles =
    path:
    with file-tree;
    with predicates;
    (collect path (
      prune (filter isNixFile (_and (_not isDotFile) (_not (startsWith "_"))) (scan path))
    ));

  defaultDoughs = attrs.fold (
    map (
      path:
      let
        expr = import path;
      in
      if builtins.isFunction expr then expr inputs else expr
    ) (collectFiles ./doughs)
  );

  mkFlake = inputs: _mkFlake { inputs' = inputs; };

  _mkFlake =
    args@{ inputs' }:
    expr:
    let
      import' =
        expr':

        if builtins.isPath expr' then
          if builtins.readFileType expr' == "directory" then
            import' (
              map (
                path:
                let
                  module = import path;
                in
                if builtins.isFunction module then module inputs' else module
              ) (collectFiles expr')
            )
          else
            import' (import expr')

        else if builtins.isList expr' then
          with attrs;
          let
            doughs' = (attrs.fold (map (module: module.bakery.doughs or { }) expr')).doughs or { };

            doughs = if doughs'.disableDefaults or false then doughs' else defaultDoughs // doughs';

            collected = (collect (builtins.attrNames doughs) (map (module: module.bakery or { }) expr'));

            outputs =
              (
                self':
                (builtins.foldl' (acc: set: mergeRecursive acc set) { } (
                  builtins.attrValues (
                    builtins.mapAttrs (
                      name: value:
                      (doughs.${name}) (
                        args
                        // {
                          inherit self';
                          list = value;
                        }
                      )
                    ) collected
                  )
                ))
              )
                outputs;
          in
          outputs

        else if builtins.isFunction expr' then
          import' (expr' inputs')

        else
          import' [ expr' ];

    in
    import' expr;
}
