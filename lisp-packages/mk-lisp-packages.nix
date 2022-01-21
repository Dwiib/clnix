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
    in stdenv.mkDerivation args) qlSystemInfo;

  # an attrset of derivations, mapping project names to derivations that
  # collect (via copies) the systems provided by the package, and test them
  qlProjects = builtins.mapAttrs (projectName: projectInfo:
    let
      systemNames = builtins.concatMap builtins.attrNames
        (builtins.attrValues projectInfo.systems);
      systems = builtins.map (systemName: qlSystems.${systemName}) systemNames;
      args = {
        pname = "ql-project-" + projectName;
        version = qlVersions.${projectName};

        nativeBuildInputs = [ lisp ];
        buildInputs = systems;

        unpackPhase = ''
          runHook preUnpack

          mkdir -p $out/lib
          for system in ${toString systems}; do
            for f in $system/lib/*; do
              cp -r $f $out/lib/
            done
            find $out -type d -exec chmod 755 {} \;
            find $out -type f -exec chmod 644 {} \;
          done

          mkdir -p $out/src
          tar -xzC $out/src -f ${projectInfo.src}
          for asd in ${toString (builtins.attrNames projectInfo.systems)}; do
            ln -s $out/src/${projectInfo.prefix}/$asd $out/src/
          done

          runHook postUnpack
        '';

        configurePhase = ''
          runHook preConfigure

          mkdir -p $out/lib
          CL_SOURCE_REGISTRY="$out/src:''${CL_SOURCE_REGISTRY:-}"
          ASDF_OUTPUT_TRANSLATIONS="$out/src:$out/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
          export CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS

          runHook postConfigure
        '';

        asdfSystemNames = systemNames;
        doCheck = true;
        checkPhase = ''
          runHook preBuild

          ${lisp.loadCommand [ ./common.lisp ./check-phase.lisp ]}

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          runHook postInstall
        '';

        setupHook = writeText "setup-hook" ''
          addToSearchPath CL_SOURCE_REGISTRY "@out@/src"
          addToSearchPath ASDF_OUTPUT_TRANSLATIONS "@out@/src"
          addToSearchPath ASDF_OUTPUT_TRANSLATIONS "@out@/lib"
        '';

        passthru.src = projectInfo.src;
      };
    in stdenv.mkDerivation args) quicklisp.projects;

  # a derivation, which is simply a linkFarm of all the projects in Quicklisp
  # (and, by extension, all the systems), for easily building the world
  allQuicklispProjects = linkFarm "all-quicklisp-projects" (lib.mapAttrsToList
    (projectName: projectDrv: {
      name = projectName;
      path = projectDrv;
    }) qlSystems);

in { inherit allQuicklispProjects mkDerivation; } // qlProjects // otherPackages
