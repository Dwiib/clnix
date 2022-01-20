{ fetchurl, lib }:

{ version ? "latest" }:

let
  hashes = lib.importJSON ./hashes.json;
  projects = lib.importJSON (./. + "/dist-${version}.json");

in builtins.mapAttrs (pname:
  { md5, systems, url }: {
    src = fetchurl {
      inherit url;
      sha256 = hashes.${md5};
    };
    inherit systems;
  }) projects
