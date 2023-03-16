{ ccl, lib }:

ccl.overrideAttrs (old: {
  passthru.loadCommand = files:
    lib.escapeShellArgs ([ "ccl" "--batch" ]
      ++ builtins.concatMap (file: [ "--load" "${file}" ]) files);
})
