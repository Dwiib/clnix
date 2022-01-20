{ lisp, lispPackages, quicklisp }:

let
  mkDerivation =
    lispPackages.callPackage ./make-derivation.nix { inherit lisp; };
  quicklispOverrides = lispPackages.callPackage ../quicklisp/overrides.nix { };
  quicklispPackages = builtins.mapAttrs (_:
    { name, prefix, src, systems }:
    mkDerivation ({
      inherit src;
      asdfSystems = systems;
      name = prefix;
      doCheck = true;
    } // (quicklispOverrides.${name} or { })
      // (quicklispOverrides.${prefix} or { }))) quicklisp;

in { inherit mkDerivation; } // quicklispPackages
