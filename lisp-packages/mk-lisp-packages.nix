{ callPackage, lib, linkFarm, lisp, lispPackages, quicklisp, stdenv, writeText
}:

let
  mkDerivation =
    lispPackages.callPackage ./make-derivation.nix { inherit lisp; };
  otherPackages = callPackage ../pkgs { inherit lispPackages; };
  quicklispOverrides = lispPackages.callPackage ../quicklisp/overrides.nix { };

  # Branches on whether a list contains zero, one, or greater than one element.
  zoi = { zero, one ? (x: x), n }:
    xs:
    let count = builtins.length xs;
    in if count == 0 then
      zero
    else if count == 1 then
      one (builtins.head xs)
    else
      n xs;

  # an attrset of attrsets, mapping system names to system info attrsets
  qlSystemInfo = builtins.mapAttrs (systemName:
    zoi {
      zero =
        builtins.abort "No system named ${systemName}; this is a bug in clnix";
      n = _:
        builtins.abort
        "Multiple Quicklisp projects provide system ${systemName}";
    }) quicklisp.systems;

  # an attrset of strings, mapping project names to their version strings.
  qlVersions = builtins.mapAttrs (projectName: projectInfo:
    let inherit (projectInfo) prefix;
    in if lib.hasPrefix (projectName + "-") prefix then
      lib.removePrefix (projectName + "-") prefix
    else if lib.hasPrefix (projectName + "_") prefix then
      lib.removePrefix (projectName + "_") prefix
    else
      prefix) quicklisp.projects;

  # an attrset of derivations, mapping system names to derivations that build
  # them (but do not test them)
  qlSystems = builtins.mapAttrs (systemName: systemInfo:
    let
      projectName = systemInfo.project;
      projectInfo = quicklisp.projects.${projectName};
      inherit (projectInfo) prefix;
      depSystemNames = zoi {
        zero = builtins.abort
          "Could not find system ${systemName} in project ${projectName}; this is a bug in clnix";
        n = _:
          builtins.abort
          "Multiple .asd files in project ${projectName} defined the system ${systemName}";
      } (lib.zipAttrs (builtins.attrValues projectInfo.systems)).${systemName};
      depSystems = builtins.map (depSystemName: qlSystems.${depSystemName})
        (builtins.filter (systemName: systemName != "asdf") depSystemNames);
      args = {
        pname = "ql-system-" + lib.strings.sanitizeDerivationName systemName;
        version = qlVersions.${projectName};

        src = projectInfo.src;
        nativeBuildInputs = [ lisp ];
        propagatedBuildInputs = depSystems;

        setSourceRoot = ''
          mkdir -p $out/src
          mv ${prefix} $out/src/${prefix}
          ln -s $out/src/${prefix}/${systemInfo.asd} $out/src/
          sourceRoot=$out/src
        '';

        configurePhase = ''
          runHook preConfigure

          mkdir -p $out/lib
          CL_SOURCE_REGISTRY="$out/src:''${CL_SOURCE_REGISTRY:-}"
          ASDF_OUTPUT_TRANSLATIONS="$out/src:$out/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
          export CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS

          runHook postConfigure
        '';

        asdfSystemNames = [ systemName ];
        buildPhase = ''
          runHook preBuild

          ${lisp.loadCommand [ ./common.lisp ./build-phase.lisp ]}

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          runHook postInstall
        '';

        setupHook = writeText "setup-hook" ''
          CL_SOURCE_REGISTRY="@out@/src:''${CL_SOURCE_REGISTRY:-}"
          ASDF_OUTPUT_TRANSLATIONS="@out@/src:@out@/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
          export CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS
        '';
      };
    in stdenv.mkDerivation
    (args // ((quicklispOverrides.${systemName} or (_: { })) args)))
    qlSystemInfo;

  # a derivation, which is simply a linkFarm of all the systems in Quicklisp,
  # for easily testing that everything works.
  #
  # TODO: Add a checkPhase (or a flake check?) that runs all their tests too.
  allQuicklispSystems = linkFarm "all-quicklisp-systems" (lib.mapAttrsToList
    (systemName: systemDrv: {
      name = systemName;
      path = systemDrv;
    }) qlSystems);

in { inherit allQuicklispSystems mkDerivation; } // qlSystems // otherPackages
