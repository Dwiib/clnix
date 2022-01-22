{
  description = "An alternative packaging for Common Lisp packages in Nix.";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        mkLispPackages = { lisp, quicklisp ? mkQuicklisp { } }:
          pkgs.lib.makeScope pkgs.newScope (self:
            pkgs.callPackage ./lisp-packages/mk-lisp-packages.nix {
              inherit lisp quicklisp;
              lispPackages = self;
            });
        mkQuicklisp = pkgs.callPackage ./quicklisp { };
        wrapLisp = lisp:
          lisp // {
            packages = mkLispPackages { inherit lisp; };
          };
      in rec {
        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.perl
            pkgs.perlPackages.FileSlurp
            pkgs.perlPackages.JSONMaybeXS
            pkgs.perlPackages.LWP
          ];
        };
        packages = { sbcl = wrapLisp (pkgs.callPackage ./impls/sbcl.nix { }); };
      });
}
