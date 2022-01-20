{ asdf, sbcl }:

sbcl.overrideAttrs (old: {
  postPatch = old.postPatch + ''
    cp ${asdf}/lib/common-lisp/asdf/build/asdf.lisp ./contrib/asdf/asdf.lisp
  '';
})
