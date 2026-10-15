{
  pkgs,
  lib,
  stdenv,
  fetchurl,
  rpmextract,
  makeWrapper,
  jdk17 ? pkgs.jdk17.override { enableJavaFX = true; },
  fontconfig,
  glib,
  gtk3,
  libXtst,
  libXrender,
  libXext,
  libX11,
}:

stdenv.mkDerivation rec {
  pname = "sqldeveloper";
  version = "26.2.0-186.2220";

  src = fetchurl {
    url = "https://download.oracle.com/otn_software/java/sqldeveloper/sqldeveloper-${version}.noarch.rpm";
    sha256 = "sha256-8jZrdG9aQrQxRIywdga94cR8KDmMjX5092ZeZ1qz/e4=";
  };

  nativeBuildInputs = [
    rpmextract
    makeWrapper
  ];

  buildInputs = [
    jdk17
    fontconfig
    glib
    gtk3
    libXtst
    libXrender
    libXext
    libX11
  ];

  unpackPhase = ''
    rpmextract $src
  '';

  installPhase = ''
    mkdir -p $out/share/sqldeveloper $out/bin

    cp -r opt/sqldeveloper/* $out/share/sqldeveloper/

    echo "SetJavaHome ${jdk17}" >> $out/share/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf

    # Wrap the binary using makeWrapper to inject LD_LIBRARY_PATH and Java options 
    # so JavaFX can locate its GTK/glass bindings at runtime.
    makeWrapper $out/share/sqldeveloper/sqldeveloper.sh $out/bin/sqldeveloper \
      --prefix PATH : "${lib.makeBinPath [ jdk17 ]}" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          gtk3
          glib
          fontconfig
          libXtst
          libXrender
          libXext
          libX11
        ]
      }" \
      --set JAVA_HOME "${jdk17}" \
      --set-default GDK_BACKEND x11
  '';

  meta = with lib; {
    description = "Oracle SQL Developer (GUI for Database Development)";
    homepage = "https://www.oracle.com/database/sqldeveloper/";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    license = licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
