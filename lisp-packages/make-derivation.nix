{ lib, lisp, stdenv, writeText }:

args:

stdenv.mkDerivation (args // {
  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ lisp ];

  asdfSystemNames = args.asdfSystemNames or (if args ? pname then
    [ args.pname ]
  else
    [ args.name ]);

  postUnpack = args.postUnpack or ''
    # This is fragile!
    cd "$NIX_BUILD_TOP"
    mkdir "$out"
    mv "$sourceRoot" "$out/src"
    sourceRoot="$out/src"
    cd "$out/src"
  '';

  configurePhase = args.configurePhase or ''
    runHook preConfigure

    mkdir $out/lib
    CL_SOURCE_REGISTRY="$out/src:''${CL_SOURCE_REGISTRY:-}"
    ASDF_OUTPUT_TRANSLATIONS="$out/bin:$out/bin:''${ASDF_OUTPUT_TRANSLATIONS:-}"
    ASDF_OUTPUT_TRANSLATIONS="$out/src:$out/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
    export CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS

    runHook postConfigure
  '';

  buildPhase = args.buildPhase or ''
    runHook preBuild

    while [[ ! -f "$NIX_BUILD_TOP/.clnix-finished-binaries" ]]; do
      ${lisp.loadCommand [ ./common.lisp ./build-phase.lisp ]}
    done

    runHook postBuild
  '';

  checkPhase = args.checkPhase or ''
    runHook preCheck

    ${lisp.loadCommand [ ./common.lisp ./check-phase.lisp ]}

    runHook postCheck
  '';

  installPhase = args.installPhase or ''
    runHook preInstall

    # We already built everything into $out, so no need to actually do
    # anything.

    runHook postInstall
  '';

  setupHook = args.setupHook or writeText "setup-hook" ''
    CL_SOURCE_REGISTRY="@out@/src:''${CL_SOURCE_REGISTRY:-}"
    ASDF_OUTPUT_TRANSLATIONS="@out@/src:@out@/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
    export CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS
  '';

  # TODO: Only enable this for Lisp implementations that depend on it.
  dontStrip = args.dontStrip or true;
})
