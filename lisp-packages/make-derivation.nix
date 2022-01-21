{ lib, lisp, lispPackages, stdenv }:

args:

let
  cleanArgs = lib.filterAttrs (k: _: !(builtins.elem k [ "asdfSystems" ])) args;

in stdenv.mkDerivation (cleanArgs // {
  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ lisp ];

  asdfSystemNames = args.asdfSystemNames or (if args ? pname then
    [ args.pname ]
  else
    [ args.name ]);

  setSourceRoot = args.setSourceRoot or ''
    mkdir -p "$out/src"
    for i in *; do
      mv "$i" "$out/src/"
    done
    sourceRoot="$out/src"
  '';

  configurePhase = args.configurePhase or ''
    runHook preConfigure

    mkdir "$out/lib"
    addToSearchPath CL_SOURCE_REGISTRY "$out/src"
    addToSearchPath ASDF_OUTPUT_TRANSLATIONS "$out/src"
    addToSearchPath ASDF_OUTPUT_TRANSLATIONS "$out/lib"

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

  setupHook = ./setup-hook.sh;
})
