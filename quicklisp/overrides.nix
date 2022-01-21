{ }:

{
  swank = old: {
    patchPhase = ''
      sed -ie "s|(default-fasl-dir)|#p\"$out/lib/slime-v2.26.1/\"|" slime-v2.26.1/swank-loader.lisp
    '';
  };
}
