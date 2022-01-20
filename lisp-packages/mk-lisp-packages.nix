{ callPackage, debugNix ? false, lib, lisp, lispPackages, quicklisp }:

let
  mkDerivation =
    lispPackages.callPackage ./make-derivation.nix { inherit lisp; };
  otherPackages = callPackage ../pkgs { inherit lispPackages; };
  quicklispOverrides = lispPackages.callPackage ../quicklisp/overrides.nix { };

  projectForSystem = systemName:
    let
      projects = quicklisp.systems.${systemName};
      count = builtins.length projects;
    in if count == 0 then
      builtins.abort "Could not find system ${systemName}"
    else if count == 1 then
      (builtins.head projects).project
    else
      builtins.abort
      "Found ${count} Quicklisp projects that provide system ${systemName}";
  trace = if debugNix then builtins.trace else _: x: x;
  uniqSortListOfStrings = xs:
    lib.uniqList { inputList = builtins.sort builtins.lessThan xs; };
  quicklispMkDerivationArgsForProject = projectName:
    let
      combinedMatches =
        builtins.filter (combined: builtins.elem projectName combined.projects)
        quicklispOverrides.combined;
      combinedMatchCount = builtins.length combinedMatches;
      isCombined = combinedMatchCount == 1;
      combinedMatch = builtins.head combinedMatches;

      # list of strings, names of projects in the derivation
      projectNames = if combinedMatchCount == 0 then
        [ projectName ]
      else if combinedMatchCount == 1 then
        combinedMatch.projects
      else
        builtins.abort
        "quicklispOverrides.combined had ${combinedMatchCount} combined derivations for ${projectName}";

      # mkDerivation args, just the name (and any derived properties that we can compute)
      nameAndVersion = if isCombined then {
        name = combinedMatch.name or ("combined-"
          + lib.concatStringsSep "+" combinedMatch.projects);
      } else rec {
        name = "${pname}-${version}";
        pname = projectName;
        version = lib.removePrefix (projectName + "-")
          quicklisp.projects.${projectName}.prefix;
      };

      # attrset of lists of strings, mapping the names of systems in the
      # derivation to the systems they depend on
      systems = builtins.mapAttrs (_: builtins.concatLists) (lib.zipAttrs
        (builtins.concatMap (projectName:
          builtins.attrValues quicklisp.projects.${projectName}.systems)
          projectNames));

      # unsorted list of strings with possible duplicates, names of systems the
      # derivation depends on
      depSystems' = builtins.concatLists (builtins.attrValues systems);

      # sorted list of strings without duplicates, names of systems other than
      # asdf and the systems in the derivation that the derivation depends on
      depSystems = uniqSortListOfStrings (builtins.filter (systemName:
        systemName != "asdf" && !(builtins.hasAttr systemName systems))
        depSystems');

      # sorted list of strings without duplicates, names of projects the
      # derivation depends on
      depProjects =
        uniqSortListOfStrings (builtins.map projectForSystem depSystems);

      # list of derivations the derivation depends on
      depDerivations =
        builtins.map (projectName: quicklispPackages.${projectName})
        depProjects;

      # mkDerivation args
      args = nameAndVersion // {
        propagatedBuildInputs = depDerivations;
        asdfSystemNames = builtins.attrNames systems;
        doCheck = true;
        srcs = builtins.map (projectName: quicklisp.projects.${projectName}.src)
          projectNames;
      } // ((quicklispOverrides.projects.${nameAndVersion.name} or (_: { }))
        args);
    in trace "Evaluating ${projectName}" args;

  quicklispPackages = builtins.mapAttrs (projectName: _:
    mkDerivation (quicklispMkDerivationArgsForProject projectName))
    quicklisp.projects;

in { inherit mkDerivation; } // quicklispPackages // otherPackages
