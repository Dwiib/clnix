{ alexandria, fetchFromGitHub, fiveam, fiveam-asdf, iterate, mkDerivation }:

mkDerivation {
  name = "immutable";

  src = fetchFromGitHub {
    owner = "gefjon";
    repo = "immutable";
    rev = "187a6c89ab14321ea5a4b066e74b4e3045c981c3";
    hash = "sha256-dLmHlJ8LU9ErMd4ub1C1MjDxtVdwc+GBvTYwgJw7qEg=";
  };

  propagatedBuildInputs = [ alexandria fiveam-asdf iterate ];

  doCheck = true;
  checkInputs = [ fiveam ];
}
