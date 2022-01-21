{ lib, lisp, lispPackages, stdenv, writeText }:

args:

let
  cleanArgs = lib.filterAttrs (k: _: !(builtins.elem k [ "asdfSystems" ])) args;

in stdenv.mkDerivation (cleanArgs // {
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
    ASDF_OUTPUT_TRANSLATIONS="$out/src:$out/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
    export CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS

    runHook postConfigure
  '';

  buildPhase = args.buildPhase or ''
    runHook preBuild

    ${lisp.loadCommand [ ./common.lisp ./build-phase.lisp ]}

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

  setupHook = writeText "setup-hook" ''
    CL_SOURCE_REGISTRY="@out@/src:''${CL_SOURCE_REGISTRY:-}"
    ASDF_OUTPUT_TRANSLATIONS="@out@/src:@out@/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
    export CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS
  '';
})
