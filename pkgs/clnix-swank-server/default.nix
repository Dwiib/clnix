{ iterate, lib, mkDerivation, swank }:

mkDerivation {
  pname = "clnix-swank-server";
  version = "0.0.1";

  src = ./.;

  propagatedBuildInputs = [ iterate swank ];

  meta = {
    description =
      "A simple helper to start a Swank server from the command line.";
    license = lib.licenses.cc0;
    mainProgram = "clnix-swank-server";
  };
}
