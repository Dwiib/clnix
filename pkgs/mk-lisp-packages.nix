{ lib, lisp, lispPackages, quicklisp }:

let
  mkDerivation =
    lispPackages.callPackage ./make-derivation.nix { inherit lisp; };
  quicklispOverrides = lispPackages.callPackage ../quicklisp/overrides.nix { };
  quicklispPackages = builtins.mapAttrs (_:
    { name, prefix, src, systems }:
    let
      asdfSystemNames =
        builtins.concatMap builtins.attrNames (builtins.attrValues systems);
      asdfDependencySystemNames = (builtins.filter
        (name: !(builtins.elem name asdfSystemNames) && name != "asdf")
        (builtins.concatLists (builtins.concatMap builtins.attrValues
          (builtins.attrValues systems))));
      asdfDependencyProjectNames = lib.uniqList {
        inputList = builtins.sort builtins.lessThan
          (builtins.map (systemLoadInfo: systemLoadInfo.project)
            (builtins.concatMap (system: quicklisp.systems.${system})
              asdfDependencySystemNames));
      };
      asdfDependencies = builtins.map (name: quicklispPackages.${name})
        asdfDependencyProjectNames;

      versionAttr = if lib.hasPrefix (name + "-") prefix then {
        version = lib.removePrefix (name + "-") prefix;
      } else
        { };
    in mkDerivation ({
      inherit src asdfSystemNames;
      pname = name;
      name = prefix;
      buildInputs = builtins.trace "Loading deps for ${prefix}: ${
          builtins.toJSON asdfDependencyProjectNames
        }" asdfDependencies;
      doCheck = true;
    } // versionAttr // (quicklispOverrides.${name} or { })
      // (quicklispOverrides.${prefix} or { }))) quicklisp.projects;

in { inherit mkDerivation; } // quicklispPackages
