{ alexandria, fetchFromGitHub, float-features, fset, global-vars, lib
, mkDerivation, split-sequence, trivia, trivial-garbage }:

mkDerivation {
  pname = "coalton";
  version = "20220526-git";

  src = fetchFromGitHub {
    owner = "coalton-lang";
    repo = "coalton";
    rev = "976073173774debfd0619f85a4befc40cc47b06d";
    hash = "sha256-OuVv+VejGIEcit0LMrMPnqpoP5vvUwTzn9kbyNIuP7c=";
  };

  propagatedBuildInputs = [
    alexandria
    float-features
    fset
    global-vars
    split-sequence
    trivia
    trivial-garbage
  ];

  meta = {
    description =
      "Coalton is an efficient, statically typed functional programming language that supercharges Common Lisp.";
    license = lib.licenses.mit;
  };
}
