{ pkgs, lib, stdenv, fetchurl }: 

stdenv.mkDerivation {
    name = "genode-toolchain-bin";
    version = "23.05";

    src = fetchurl {
        url = "https://sourceforge.net/projects/genode/files/genode-toolchain/23.05/genode-toolchain-23.05.tar.xz";
        hash = "sha256-iAiG77oPWSo9PF/7n6Y+aSy2vWQ+E8XEaNDaAnwicW4=";
    };

    sourceRoot = ".";
    dontStrip = true;

    buildInputs = with pkgs; [
        expat
        flex
        gmp
        libxcrypt-legacy
        lzma
        ncurses
        python38
        zlib
    ];

    nativeBuildInputs = with pkgs; [
        autoPatchelfHook
    ];

    installPhase = ''
        mkdir -p ''${out}
        cp -r ./usr/local/genode/tool/23.05/* "''${out}"
    '';
}