{ pkgs, lib }:

rec {
    mkGenodeBase = { src, toolchain, extraInputs ? [ ] }@args: 
    let
        buildInputs = with pkgs; [
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
        ]
        ++ extraInputs
        ++ [ toolchain ];

    in {
        inherit toolchain buildInputs;

        src = pkgs.stdenv.mkDerivation {
            inherit buildInputs;
            inherit (args) src;

            name = "genode";

            installPhase = ''
                mkdir -p ''${out}
                cp -r . ''${out}
            '';

            preFixup = ''
                patchShebangs --host $(find . -type f -executable)
            '';
        };
    };

    mkGenodeRepo = { src, name }: {
        inherit name;

        src = pkgs.stdenv.mkDerivation {
            inherit name src;

            buildPhase = ''
                mkdir -p ''${out}/repos/${name}
                cp -r . ''${out}/repos/${name}
            '';
        };
    };

    mkGenodeTree = { genodeTree, repos ? [ ], ports ? [ ] }: {
        inherit (genodeTree) toolchain;

        src = pkgs.stdenv.mkDerivation {
            inherit (genodeTree) src;

            name = "genode-tree";

            buildInputs = with pkgs; [
                rsync
            ];

            buildPhase = ''
                # Sync repos with genode tree
                ${
                    lib.lists.foldl
                        (cur: repo: cur + "rsync -a ${repo.src}/ ./\n")
                        ""
                        repos
                }

                # Sync ports with genode tree
                ${
                    lib.lists.foldl
                        (cur: port: cur + "rsync -a ${port.src}/ ./\n")
                        ""
                        ports
                }
            '';

            installPhase = ''
                mkdir -p ''${out}
                cp -r . ''${out}
            '';
        };

        buildInputs = genodeTree.buildInputs ++ (lib.lists.foldl (inputs: port: inputs ++ port.extraInputs) [ ] ports);
    };
}