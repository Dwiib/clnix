{ asdf, ecl, lib }:

ecl.overrideAttrs (old: {
  postPatch = ''
    cp ${asdf}/lib/common-lisp/asdf/build/asdf.lisp ./contrib/asdf/asdf.lisp
  '';

  passthru.loadCommand = files:
    lib.escapeShellArgs
    ([ "ecl" ] ++ builtins.concatMap (file: [ "--load" "${file}" ]) files);
})
