{ alexandria, fetchFromGitHub, float-features, fset, global-vars, lib
, mkDerivation, split-sequence, trivia }:

mkDerivation {
  pname = "coalton";
  version = "20220113-git";

  src = fetchFromGitHub {
    owner = "coalton-lang";
    repo = "coalton";
    rev = "8819e9221c32bd95dbe57a2130afdbbabad49326";
    hash = "sha256-VRN2epzQKRyGE6F1KNgUUidTE3sLvzpluD8rMz3uCoc=";
  };

  propagatedBuildInputs =
    [ alexandria float-features fset global-vars split-sequence trivia ];

  meta = {
    description =
      "Coalton is an efficient, statically typed functional programming language that supercharges Common Lisp.";
    license = lib.licenses.mit;
  };
}
