{ lispPackages }:

{
  clnix-swank-server = lispPackages.callPackage ./clnix-swank-server { };
  coalton = lispPackages.callPackage ./coalton.nix { };
}
