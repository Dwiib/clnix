{ fetchurl, lib }:

{ version ? "latest" }:

let
  distInfo = lib.importJSON (./. + "/dist-${version}.json");
  hashes = lib.importJSON ./hashes.json;

in {
  inherit (distInfo) systems;
  projects = builtins.mapAttrs (name:
    { md5, prefix, systems, url }: {
      inherit name prefix systems;
      src = fetchurl {
        inherit url;
        sha256 = hashes.${md5};
      };
    }) distInfo.projects;
}
