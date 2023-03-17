{ asdf, ccl, lib }:

ccl.overrideAttrs (old: {
  postPatch = old.postPatch + ''
    cp ${asdf}/lib/common-lisp/asdf/build/asdf.lisp ./tools/asdf.lisp
  '';

  passthru.loadCommand = files:
    lib.escapeShellArgs ([ "ccl" "--batch" ]
      ++ builtins.concatMap (file: [ "--load" "${file}" ]) files);
})
