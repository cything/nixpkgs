{
  lib,
  stdenv,
  fetchFromGitHub,
  deno,
  fetchNpmDeps,
  nodejs,
}:
stdenv.mkDerivation rec {
  pname = "single-file-cli";
  version = "2.0.73";

  src = fetchFromGitHub {
    owner = "gildas-lormeau";
    repo = "single-file-cli";
    rev = "v${version}";
    hash = "sha256-fMedP+wp1crHUj9/MVyG8XSsl1PA5bp7/HL4k+X0TRg=";
  };

  npmDeps = fetchNpmDeps {
    inherit src;
    name = pname;
    hash = "sha256-nnOMBb9mHNhDejE3+Kl26jsrTRxSSg500q1iwwVUqP8=";
  };

  nativeBuildInputs = [
    nodejs
    deno
  ];

  buildPhase = ''
    export DENO_DIR="$(mktemp -d)"
    export DENO_NO_UPDATE_CHECK=true
    mkdir -p $DENO_DIR/npm
    ln -s $src/node_modules $DENO_DIR/npm/registry.npmjs.org
    deno compile --unstable-byonm --cached-only --vendor=true --node-modules-dir=true --allow-read --allow-write --allow-net --allow-env --allow-run --ext=js --output=$out/bin/single-file --target=x86_64-unknown-linux-gnu $src/single-file
  '';

  meta = {
    description = "CLI tool for saving a faithful copy of a complete web page in a single HTML file";
    homepage = "https://github.com/gildas-lormeau/single-file-cli";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ n8henrie ];
    mainProgram = "single-file";
  };
}
