{ pkgs, lib }:

rec {
    mkGenodeSrc = { genode, repos ? { }, ports ? [ ] }: 
    let
        preparedPorts = lib.lists.forEach ports (port: preparePort genodeRepo port);
    
        # TODO: evaluate base genode source and repos separately to maximize reuse
        genodeRepo = pkgs.stdenv.mkDerivation {
            name = "genode-repo";
            src = genode;

            buildInputs = with pkgs; [
                expect
                git
                gnumake
                wget
            ];

            patchPhase = ''
                patchShebangs --host $(find . -type f -executable)
            '';

            buildPhase = ''
                # Copy repos to source directory
                ${
                    lib.lists.foldl 
                        (cur: repo: cur + "cp -r ${repos.${repo}} ./repos/${repo}\n")
                        ""
                        (builtins.attrNames repos)
                }
            '';

            installPhase = ''
                mkdir -p ''${out}
                cp -r . ''${out}
            '';
        };

        in pkgs.stdenv.mkDerivation {
            name = "genode-src";

            src = genodeRepo;

            buildInputs = with pkgs; [
                rsync
            ];

            buildPhase = ''
                # Copy ports to contrib directory
                ${
                    lib.lists.foldl
                        (cur: port: cur + "rsync -a ${port}/ ./\n")
                        ""
                        preparedPorts
                }
            '';

            installPhase = ''
                mkdir -p ''${out}
                cp -r . ''${out}
            '';
        };

    fetchPort = args:
        if args.type == "archive"
        then
            builtins.fetchurl {
                inherit (args) url sha256;
            }

        else if args.type == "git"
        then
            builtins.fetchGit {
                inherit (args) url rev;
            }

        else throw "unsupported port type ${args.type}";

    preparePort = genodeSrc: args:
        let
            download = fetchPort args;
        
        in pkgs.stdenv.mkDerivation {
            inherit (args) name;

            srcs = [
                genodeSrc
                download
            ];

            buildInputs = with pkgs; [
                git
                wget
            ]
            ++ (lib.attrsets.attrByPath [ "extraInputs" ] [ ] args);

            preUnpack = ''
                export GENODE_DIR="$(pwd)/genode-src";
            '';

            unpackPhase = ''
                runHook preUnpack

                mkdir -p "''${GENODE_DIR}"
                cp -r ${genodeSrc}/* "''${GENODE_DIR}"

                ${
                    if args.type == "git"
                    then
                        ''
                            export DOWNLOAD_DIR=''${GENODE_DIR}/contrib/${args.name}-${args.hash}/${args.dir}

                            mkdir -p "''${DOWNLOAD_DIR}"
                            cp -r ${download}/* "''${DOWNLOAD_DIR}"
                        ''
                    else
                        ''
                            export DOWNLOAD_DIR=''${GENODE_DIR}/contrib/cache

                            mkdir -p "''${DOWNLOAD_DIR}"
                            cp -r ${download} "''${DOWNLOAD_DIR}/${args.sha256}_$(stripHash ${download})"
                        ''
                }

                chmod -R +w ''${GENODE_DIR}
            '';

            patchPhase = ''
                patch ''${GENODE_DIR}/tool/ports/mk/install.mk ${./prepare_port.patch}
            '';

            buildPhase = ''
                ''${GENODE_DIR}/tool/ports/prepare_port ${args.name}
            '';

            preFixup = ''
                patchShebangs --host $(find . -type f -executable)
            '';

            installPhase = ''
                mkdir -p ''${out}/contrib
                cp -r ''${GENODE_DIR}/contrib/${args.name}-${args.hash} ''${out}/contrib
            '';
        };
}