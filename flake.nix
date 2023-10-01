{
  description = "An alternative packaging for Common Lisp packages in Nix.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/23.05";
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
          lisp // rec {
            packages = mkLispPackages { inherit lisp; };
            swank = packages.clnix-swank-server;
          };
      in rec {
        checks = let
          quicklisp-to-nix-systems-path =
            "${nixpkgs}/pkgs/development/lisp-modules/quicklisp-to-nix-systems.txt";
          quicklisp-to-nix-systems = builtins.filter (s: s != "")
            (nixpkgs.lib.splitString "\n"
              (builtins.readFile quicklisp-to-nix-systems-path));
          quicklisp-to-nix-systems-non-broken =
            builtins.filter (s: !(s == "cl-webkit2" && pkgs.stdenv.isDarwin))
            quicklisp-to-nix-systems;
          quicklisp-to-nix-systems-test = lisp:
            let
              entries = builtins.map (systemName: {
                name = systemName;
                path = lisp.packages.${systemName};
              }) quicklisp-to-nix-systems-non-broken;
            in pkgs.linkFarm "quicklisp-to-nix-systems/${lisp.pname}" entries;
        in {
          "quicklisp-to-nix-systems/ccl" =
            quicklisp-to-nix-systems-test packages.ccl;
          "quicklisp-to-nix-systems/ecl" =
            quicklisp-to-nix-systems-test packages.ecl;
          "quicklisp-to-nix-systems/sbcl" =
            quicklisp-to-nix-systems-test packages.sbcl;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs =
            [ (pkgs.python3.withPackages (ps: [ ps.requests ps.tqdm ])) ];
        };

        packages = {
          asdf = pkgs.callPackage ./pkgs/asdf.nix { };
          ccl = wrapLisp
            (pkgs.callPackage ./impls/ccl.nix { inherit (packages) asdf; });
          ecl = wrapLisp
            (pkgs.callPackage ./impls/ecl.nix { inherit (packages) asdf; });
          sbcl = wrapLisp
            (pkgs.callPackage ./impls/sbcl.nix { inherit (packages) asdf; });
        };
      });
}
