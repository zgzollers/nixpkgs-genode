{
    inputs = {
        nixpkgs.url = "nixpkgs/nixpkgs-unstable";

        zgzollers-genode = {
            url = "github:zgzollers/nixpkgs-genode";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        flake-compat = {
            url = "github:edolstra/flake-compat";
            flake = false;
        };
    };

    outputs = { self, nixpkgs, zgzollers-genode, flake-compat }: 
    let
        system = "x86_64-linux";

        pkgs = import nixpkgs { 
            inherit system; 

            overlays = [
                zgzollers-genode.overlays.default
            ];
        };

        genodeSrc = zgzollers-genode.lib.mkGenodeSrc {
            rev = "5fdea3a5953e07430e8c45a2b974cf9d0de4228f";
        };

    in {
        packages.${system}.default = pkgs.stdenv.mkDerivation {
            name = "genode-project";

            srcs = [
                ./build.conf
                ./repos
                genodeSrc
            ];

            sourceRoot = "./src";

            buildInputs = with pkgs; [
                # TODO: Find a way to declare these dependencies in the genodeSrc lib function
                # There are duplicates that exist, but the dependencies wont propegate to this
                # environment if they are declared in that function.

                bc
                bison
                expect
                flex
                git
                gnumake
                libxml2
                qemu_kvm
                xorriso
                wget

            ] ++ [
                toolchain-bin
            ];

            dontStrip = true;

            CROSS_DEV_PREFIX = "${pkgs.toolchain-bin}/bin/genode-x86-";

            # Make dev shell cleaner by placing build artifacts in a separate directory. This also makes
            # the unpackPhase idempotent.
            preUnpack = ''
                rm -rf ./src
                mkdir -p ./src
            '';

            unpackCmd = "cp -r $curSrc ./src/$(stripHash $curSrc)";

            postUnpack = ''
                cd ./src

                export GENODE_DIR="$(pwd)/${genodeSrc.name}"

                ''${GENODE_DIR}/tool/create_builddir x86_64 BUILD_DIR=./build
                rm -f ./build/etc/build.conf
                ln -s $(pwd)/build.conf ./build/etc/build.conf

                ln -s $(pwd)/repos/* ''${GENODE_DIR}/repos

                ''${GENODE_DIR}/tool/ports/prepare_port nova grub2

                cd ..
            '';

            buildPhase = ''
                cd ./build
                make run/hello
            '';

            installPhase = ''

            '';
        };
    };
}
