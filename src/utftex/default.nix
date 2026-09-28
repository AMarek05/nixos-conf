{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
}:

stdenv.mkDerivation rec {
  pname = "utftex";
  version = "1.31";

  src = fetchFromGitHub {
    owner = "bartp5";
    repo = "libtexprintf";
    tag = "v${version}";
    hash = "sha256-OXDcohfSfik0H1MpoznN267OVTYkW75N+TIF6lRRvZ0=";
  };

  nativeBuildInputs = [
    autoreconfHook
  ];

  meta = {
    description = "Converts ASCII LaTeX math expressions into 2D Unicode plain text";
    homepage = "https://github.com/bartp5/libtexprintf";
    license = lib.licenses.gpl3;
    mainProgram = "utftex";
    platforms = lib.platforms.all;
  };
}
