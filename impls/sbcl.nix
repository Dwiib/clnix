{ asdf, lib, sbcl }:

sbcl.overrideAttrs (old: {
  postPatch = old.postPatch + ''
    cp ${asdf}/lib/common-lisp/asdf/build/asdf.lisp ./contrib/asdf/asdf.lisp
  '';

  passthru.loadCommand = files:
    lib.escapeShellArgs ([ "sbcl" "--non-interactive" ]
      ++ builtins.concatMap (file: [ "--load" "${file}" ]) files);
})
