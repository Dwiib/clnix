{ fetchurl, lib }:

{ version ? "latest" }:

let
  hashes = lib.importJSON ./hashes.json;
  projects = lib.importJSON (./. + "/dist-${version}.json");

in builtins.mapAttrs (name:
  { md5, prefix, systems, url }: {
    inherit name prefix systems;
    src = fetchurl {
      inherit url;
      sha256 = hashes.${md5};
    };
  }) projects
