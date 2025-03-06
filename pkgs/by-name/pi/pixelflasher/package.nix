{
  stdenv,
  lib,
  fetchFromGitHub,
  wrapGAppsHook3,
  python3Packages,
  makeDesktopItem,
  copyDesktopItems,
}:
python3Packages.buildPythonApplication rec {
  pname = "pixelflasher";
  version = "7.10.0.0";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "badabing2005";
    repo = "PixelFlasher";
    tag = "${version}";
    hash = "sha256-7gDTPbf+kaF8c4G+Vl8Vyzv2TdMzzNhWW6V6xUdGtBU=";
  };

  desktopItems = [
    (makeDesktopItem {
      name = "PixelFlasher";
      exec = "${pname}";
      icon = "pixelflasher";
      desktopName = "PixelFlasher";
      genericName = "Pixel™ phone flashing GUI utility with features";
      categories = [ "Development" ];
    })
  ];

  dependencies = with python3Packages; [
    attrdict
    httplib2
    platformdirs
    requests
    darkdetect
    markdown
    pyperclip
    protobuf4
    six
    bsdiff4
    lz4
    psutil
    json5
    beautifulsoup4
    chardet
    cryptography
    rsa
    wxpython
  ];

  nativeBuildInputs = [
    wrapGAppsHook3
    python3Packages.pyinstaller
    copyDesktopItems
  ];

  buildPhase =
    let
      specFile =
        if stdenv.hostPlatform.isDarwin then
          if stdenv.hostPlatform.isAarch64 then "build-on-mac" else "build-on-mac-intel-only"
        else
          "build-on-linux";
    in
    ''
      runHook preBuild

      pyinstaller --clean --noconfirm --log-level=DEBUG ${specFile}.spec

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/icons/hicolor/64x64/apps
    cp dist/PixelFlasher $out/bin/${pname}
    cp images/icon-64.png $out/share/icons/hicolor/64x64/apps/${pname}.png

    runHook postInstall
  '';

  meta = {
    description = "Pixel™ phone flashing GUI utility with features";
    homepage = "https://github.com/badabing2005/PixelFlasher";
    changelog = "https://github.com/badabing2005/PixelFlasher/releases";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ cything ];
    mainProgram = "pixelflasher";
    platforms = lib.platforms.linux;
  };
}
