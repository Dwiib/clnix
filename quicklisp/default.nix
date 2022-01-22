{ fetchurl, lib }:

{ version ? "latest" }:

let
  distInfo = lib.importJSON (./. + "/dist-${version}.json");
  hashes = lib.importJSON ./hashes.json;

in {
  inherit (distInfo) systems;
  projects = builtins.mapAttrs (name:
    { asd-files, md5, prefix, system-deps, url }: {
      inherit asd-files name prefix system-deps;
      src = fetchurl {
        inherit url;
        sha256 = hashes.${md5};
      };
    }) distInfo.projects;
}
