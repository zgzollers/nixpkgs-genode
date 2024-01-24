{
    inputs = {
        # Nix flakes

        nixpkgs.url = "nixpkgs/nixpkgs-unstable";

        zgzollers-genode = {
            url = "github:zgzollers/nixpkgs-genode";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        flake-compat = {
            url = "github:edolstra/flake-compat";
            flake = false;
        };

        # Genode source repositories

        genode = {
            url = "github:genodelabs/genode/23.11";
            flake = false;
        };

        genode-world = {
            url = "github:genodelabs/genode-world";
            flake = false;
        };
    };

    outputs = { self, nixpkgs, zgzollers-genode, flake-compat, genode, genode-world }: 
    let
        system = "x86_64-linux";

        pkgs = import nixpkgs { 
            inherit system; 

            overlays = [
                zgzollers-genode.overlays.default
            ];
        };

        genodeSrc = zgzollers-genode.lib.mkGenodeSrc {
            inherit genode;

            repos = {
                "world" = genode-world;
            };

            ports = import ./.nix/ports.nix;
        };

    in {
        packages.${system}.default = pkgs.stdenv.mkDerivation rec {
            name = "genode-project";

            srcs = [
                ./build.conf
                ./repos
                genodeSrc
            ];

            sourceRoot = "./.build";

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

                toolchain-bin
            ];

            dontStrip = true;

            shellHook = ''
                export CROSS_DEV_PREFIX="${pkgs.toolchain-bin}/bin/genode-x86-";

                export SOURCE_DIR="$(pwd)/${sourceRoot}";
                export GENODE_DIR="''${SOURCE_DIR}/${genodeSrc.name}";
                export BUILD_DIR="''${SOURCE_DIR}/build";
            '';

            preUnpack = ''
                eval "''${shellHook}"

                rm -rf "''${SOURCE_DIR}"
                mkdir -p "''${SOURCE_DIR}"
            '';

            unpackCmd = "cp -r $curSrc $SOURCE_DIR/$(stripHash $curSrc)";

            postUnpack = ''
                ''${GENODE_DIR}/tool/create_builddir x86_64
                rm -f "''${BUILD_DIR}/etc/build.conf"
                ln -s "''${SOURCE_DIR}/build.conf" "''${BUILD_DIR}/etc/build.conf"

                ln -s ''${SOURCE_DIR}/repos/* "''${GENODE_DIR}/repos"
            '';

            buildPhase = ''
                make -C "''${BUILD_DIR}" run/hello
            '';

            installPhase = ''
                mkdir -p ''${out}
                cp ''${BUILD_DIR}/var/run/hello.iso ''${out}
            '';
        };
    };
}
