{ asdf, fetchurl }:

asdf.overrideAttrs (old: rec {
  version = "3.3.6";
  src = fetchurl {
    url = "http://common-lisp.net/project/asdf/archives/asdf-${version}.tar.gz";
    hash = "sha256-NkjvNlLqJnBAfOxC9ECTtmuS5K+0v5ZXOw2xt8l7vgk=";
  };
})
