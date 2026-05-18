{

  description = "unified configs";

  inputs = { };

  outputs =
    inputs@{ ... }:
    {
      lib = import ./lib inputs;
    };
}
