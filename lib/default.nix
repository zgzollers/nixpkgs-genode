{ pkgs, lib }:

let
    src = import ./src/src.nix { inherit pkgs lib; };

    ports = import ./ports/ports.nix { inherit pkgs lib; };

    build = import ./build/build.nix {
        inherit pkgs lib;
        inherit (src) mkGenodeTree mkGenodeRepo;
        inherit (ports) preparePort;
    };

in src // ports // build