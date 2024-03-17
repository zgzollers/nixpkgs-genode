{
    inputs = {
        # Nix inputs

        nixpkgs.url = "nixpkgs/nixpkgs-unstable";

        genode-utils = {
            url = "github:zgzollers/nixpkgs-genode";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        flake-compat = {
            url = "github:edolstra/flake-compat";
            flake = false;
        };

        # Genode source repository

        genode = {
            url = "github:genodelabs/genode/24.02";
            flake = false;
        };

        # Additional Genode repositories

        genode-world = {
            url = "github:genodelabs/genode-world";
            flake = false;
        };
    };

    outputs = { self, nixpkgs, genode-utils, flake-compat, genode, genode-world }: 
    let
        system = "x86_64-linux";

        pkgs = import nixpkgs { 
            inherit system; 

            overlays = [
                genode-utils.overlays.packages
                genode-utils.overlays.lib
            ];
        };
    in {
        packages.${system}.default = genode-utils.lib.mkGenodeDerivation rec {
            genodeTree = genode-utils.lib.mkGenodeBase {
                src = genode;
                toolchain = pkgs.genode.toolchain-bin;
            };

            name = "hello.iso";

            buildConf = ./build.conf;

            repos = [
                { name = "world"; src = genode-world; }
                { name = "lab"; src = ./repos/lab; }
            ];

            ports = (import ./.nix/ports.nix { inherit pkgs; });

            buildPhase = ''
                make run/hello
            '';

            installPhase = ''
                cp "''${BUILD_DIR}/var/run/hello.iso" "''${out}"
            '';
        };
    };
}