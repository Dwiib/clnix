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
          mkLispPackages = { lisp, quicklisp ? legacyPackages.quicklisp { } }:
            pkgs.lib.makeScope pkgs.newScope (self:
              pkgs.callPackage ./pkgs/mk-lisp-packages.nix {
                inherit lisp quicklisp;
                lispPackages = self;
              });
          quicklisp = pkgs.callPackage ./quicklisp { };
          wrapLisp = lisp:
            lisp // {
              packages = legacyPackages.mkLispPackages { inherit lisp; };
            };
        };
        packages = {
          sbcl =
            legacyPackages.wrapLisp (pkgs.callPackage ./impls/sbcl.nix { });
        };
      });
}
