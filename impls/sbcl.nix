{ asdf, fetchurl, lib, sbcl, stdenv, texinfo, zstd }:

let
  sbclBootstrapHost =
    "${sbcl}/bin/sbcl --disable-debugger --no-userinit --no-sysinit";

in stdenv.mkDerivation rec {
  pname = "sbcl";
  version = "2.3.2";

  src = fetchurl {
    url =
      "mirror://sourceforge/project/sbcl/sbcl/${version}/${pname}-${version}-source.tar.bz2";
    hash = "sha256-RMwWLPpjMqmojHoSHRkDiCikuk9r/7d+8cexdAfLHqo=";
  };

  nativeBuildInputs = [ texinfo ];
  buildInputs = [ zstd ];

  postPatch = ''
    # Update the bundled ASDF.
    cp ${asdf}/lib/common-lisp/asdf/build/asdf.lisp ./contrib/asdf/asdf.lisp
  '';

  preBuild = ''
    export INSTALL_ROOT=$out
    mkdir -p test-home
    export HOME=$PWD/test-home
  '';

  configureFlags = [ "--fancy" ];

  buildPhase = ''
    runHook preBuild
    sh make.sh \
      --prefix=$out \
      --xc-host="${sbclBootstrapHost}" \
      --fancy
    make info -C doc/manual
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    sh install.sh
    runHook postInstall
  '';

  passthru.loadCommand = files:
    lib.escapeShellArgs ([ "sbcl" "--non-interactive" ]
      ++ builtins.concatMap (file: [ "--load" "${file}" ]) files);

  meta = {
    description =
      "Steel Bank Common Lisp (SBCL) is a high performance Common Lisp compiler";
    homepage = "http://www.sbcl.org";
    license = lib.licenses.publicDomain; # and FreeBSD

    longDescription =
      "Steel Bank Common Lisp (SBCL) is a high performance Common Lisp compiler. It is open source / free software, with a permissive license. In addition to the compiler and runtime system for ANSI Common Lisp, it provides an interactive environment including a debugger, a statistical profiler, a code coverage tool, and many other extensions.";
  };
}
