{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  };
  outputs =
    inputs@{ self
    , nixpkgs
    , ...
    }:
    let
      systems = lib.systems.flakeExposed;
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs systems;
    in
    {
      inherit (nixpkgs) lib nixosModules htmlDocs;
      legacyPackages = eachSystem (system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "openssl-1.1.1v" #TODO: this is bad but it's needed for cl+ssl
          ];
        };
        overlays = [
        ];
      });
    };
}
