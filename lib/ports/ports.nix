{ pkgs, lib }:

rec {
    fetchPort = { type, url, rev ? null, sha256 ? null }:
        if type == "archive"
        then
            builtins.fetchurl {
                inherit url sha256;
            }

        else if type == "git"
        then
            builtins.fetchGit {
                inherit url rev;

                allRefs = true;
            }

        else throw "unsupported port type ${type}";

    preparePort = { 
        genodeTree,
        name,
        type,
        hash,
        url,
        extraInputs ? [ ],
        rev ? null,
        dir ? null,
        sha256 ? null
    }: {
        inherit name type extraInputs;

        src = pkgs.stdenv.mkDerivation {
            inherit name;

            src = fetchPort { inherit type url rev sha256; };

            buildInputs = with pkgs; [
                git
                wget
            ]
            ++ extraInputs
            ++ [ genodeTree.toolchain ];

            dontStrip = true;
            dontConfigure = true;

            preUnpack = ''
                export GENODE_DIR="$(pwd)/genode";
            '';

            unpackPhase = ''
                runHook preUnpack

                mkdir -p "''${GENODE_DIR}"
                cp -r ${genodeTree.src}/* "''${GENODE_DIR}"

                ${
                    if type == "git"
                    then
                        ''
                            export DOWNLOAD_DIR=''${GENODE_DIR}/contrib/${name}-${hash}/${dir}

                            mkdir -p "''${DOWNLOAD_DIR}"
                            cp -r ''${src}/* "''${DOWNLOAD_DIR}"
                        ''
                    else
                        ''
                            export DOWNLOAD_DIR=''${GENODE_DIR}/contrib/cache

                            mkdir -p "''${DOWNLOAD_DIR}"
                            cp -r ''${src} "''${DOWNLOAD_DIR}/${sha256}_$(stripHash ''${src})"
                        ''
                }

                chmod -R +w ''${GENODE_DIR}

                # TODO: need to also patch archives after they are extracted :(
                patchShebangs --host $(find ''${GENODE_DIR}/contrib -type f -executable)
            '';

            patchPhase = ''
                patch ''${GENODE_DIR}/tool/ports/mk/install.mk ${./prepare_port.patch}
            '';

            buildPhase = ''
                ''${GENODE_DIR}/tool/ports/prepare_port ${name}
            '';

            installPhase = ''
                mkdir -p ''${out}/contrib
                cp -r ''${GENODE_DIR}/contrib/${name}-${hash} ''${out}/contrib
            '';

            preFixup = ''
                patchShebangs --host $(find . -type f -executable)
            '';
        };
    };
}