{ lib, lisp, stdenv }:

args:

let
  cleanArgs = lib.filterAttrs (k: _: !(builtins.elem k [ "asdfSystems" ])) args;

in stdenv.mkDerivation (cleanArgs // {
  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ lisp ];

  asdfSystemNames = args.asdfSystemNames or (if args ? asdfSystems then
    builtins.concatMap builtins.attrNames (builtins.attrValues args.asdfSystems)
  else if args ? pname then
    [ args.pname ]
  else
    [ args.name ]);

  configurePhase = args.configurePhase or ''
    runHook preConfigure
    addToSearchPath CL_SOURCE_REGISTRY "$(pwd)"
    addToSearchPath ASDF_OUTPUT_TRANSLATIONS "$(pwd)"
    mkdir "$out"
    addToSearchPath ASDF_OUTPUT_TRANSLATIONS "$out"
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
    ${lisp.loadCommand [ ./common.lisp ./install-phase.lisp ]}
    runHook postInstall
  '';
})
