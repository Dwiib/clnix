{ alexandria, fetchFromGitHub, float-features, fset, global-vars, mkDerivation
, split-sequence, trivia }:

mkDerivation {
  pname = "coalton";
  version = "20220113-git";

  src = fetchFromGitHub {
    owner = "coalton-lang";
    repo = "coalton";
    rev = "a1960536c344e6528366f029c169f2cf1d847462";
    hash = "sha256-jXTB6VhqK7+cQmyGH4vkLjLBl6IrnwS08F489EvQnrw=";
  };

  propagatedBuildInputs =
    [ alexandria float-features fset global-vars split-sequence trivia ];
}
