{ pkgs }:

{
    toolchain-bin = pkgs.callPackage ./toolchain-bin.nix { };
}