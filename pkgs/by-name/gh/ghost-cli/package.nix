{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnInstallHook,
  versionCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ghost-cli";
  version = "1.26.1";

  src = fetchFromGitHub {
    owner = "TryGhost";
    repo = "Ghost-CLI";
    rev = "v${finalAttrs.version}";
    hash = "sha256-2zyRkPTQBzF+7nmlHPMi4S0BAdmUwIBkwD71y1y7Pn8=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-No+Hkb2ivrCSd0S9L5QxZ8ReX9NANMRITKHFvjzRSuc=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnInstallHook
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckProgram = ''${placeholder "out"}/bin/ghost'';

  meta = {
    description = "CLI Tool for installing & updating Ghost";
    mainProgram = "ghost";
    homepage = "https://ghost.org/docs/ghost-cli/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ cything ];
  };
})
