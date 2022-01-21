{ alexandria, closer-mop, fetchFromGitHub, fset, global-vars
, introspect-environment, iterate, lisp-namespace, misc-extensions, mkDerivation
, mt19937, named-readtables, trivia, trivial-cltl2, type-i }:

mkDerivation {
  pname = "coalton";
  version = "20210113-git";

  src = fetchFromGitHub {
    owner = "coalton-lang";
    repo = "coalton";
    rev = "a1960536c344e6528366f029c169f2cf1d847462";
    hash = "sha256-jXTB6VhqK7+cQmyGH4vkLjLBl6IrnwS08F489EvQnrw=";
  };

  propagatedBuildInputs = [
    alexandria
    closer-mop
    fset
    global-vars
    introspect-environment
    iterate
    lisp-namespace
    misc-extensions
    mt19937
    named-readtables
    trivia
    trivial-cltl2
    type-i
  ];
}
