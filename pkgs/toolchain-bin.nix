{ pkgs, lib, stdenv, fetchurl }: 

stdenv.mkDerivation {
    name = "genode-toolchain-bin";

    src = fetchurl {
        url = "https://sourceforge.net/projects/genode/files/genode-toolchain/23.05/genode-toolchain-23.05.tar.xz";
        hash = "sha256-iAiG77oPWSo9PF/7n6Y+aSy2vWQ+E8XEaNDaAnwicW4=";
    };

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

    unpackPhase = ''
        mkdir -p ''${out}
        tar -xf ''${src} -C ''${out}
    '';
}