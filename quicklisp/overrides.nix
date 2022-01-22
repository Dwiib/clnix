{ }:

{
  swank = old: {
    patchPhase = ''
      # Swank uses its own non-ASDF loader / build system. This doesn't look at
      # the variables we care about, so we patch it to just hard-code in the
      # output directory for FASLs. (It's able to find itself by virtue of ASDF
      # invoking it.)
      sed -i slime-v2.26.1/swank-loader.lisp \
        -e "s|(default-fasl-dir)|#p\"$out/lib/slime-v2.26.1/\"|"

      # The aforementioned build system also uses timestamp <= instead of < to
      # determine when files are out of date, breaking Nix by always
      # considering two files of equal (in this case zeroed out) timestamp to
      # be out of date with each other.
      sed -i slime-v2.26.1/swank-loader.lisp \
        -e "s/(<= (file-write-date fasl) newest)/(< (file-write-date fasl) newest)/"
    '';
  };
}
