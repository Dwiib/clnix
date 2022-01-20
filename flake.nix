{
  description = "An alternative packaging for Common Lisp packages in Nix.";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.perl
            pkgs.perlPackages.FileSlurp
            pkgs.perlPackages.JSONMaybeXS
            pkgs.perlPackages.LWP
          ];
        };
        legacyPackages = {
          mkLispPackages = { lisp }:
            pkgs.lib.makeScope pkgs.newScope (self:
              pkgs.callPackage ./mk-lisp-packages.nix {
                inherit lisp;
                lispPackages = self;
              });
          qlnix = pkgs.callPackage ./quicklisp { };
          sbclPackages =
            legacyPackages.mkLispPackages { lisp = packages.sbcl; };
        };
        packages = { sbcl = pkgs.callPackage ./impls/sbcl.nix { }; };
      });
}
