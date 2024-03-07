{ pkgs, lib, mkGenodeTree, mkGenodeRepo, preparePort }:

{
    mkGenodeDerivation = { 
        name,
        genodeTree,
        repos ? [ ],
        ports ? [ ],
        buildConf ? ./default.conf,
        buildPhase,
        installPhase 
    }@args: 
    let
        treeWithRepos = mkGenodeTree {
            inherit genodeTree;

            repos = pkgs.lib.lists.forEach 
                repos
                (repo: mkGenodeRepo repo);
        };

        updatedTree = mkGenodeTree { 
            genodeTree = treeWithRepos;

            ports = pkgs.lib.lists.forEach 
                ports
                (port: preparePort (port // { genodeTree = treeWithRepos; }));
        };

    in pkgs.stdenv.mkDerivation rec {
        inherit (updatedTree) buildInputs;
        inherit name installPhase;

        srcs = [
            updatedTree.src
            buildConf
        ];

        sourceRoot = "./.build";

        shellHook = ''
            export CROSS_DEV_PREFIX="${updatedTree.toolchain}/bin/genode-x86-";

            export SOURCE_DIR="$(pwd)/${sourceRoot}";
            export GENODE_DIR="''${SOURCE_DIR}/${updatedTree.src.name}";
            export BUILD_DIR="''${SOURCE_DIR}/build-x86_64";
        '';

        preUnpack = ''
            eval "''${shellHook}"

            rm -rf "''${SOURCE_DIR}"
            mkdir -p "''${SOURCE_DIR}"
        '';

        unpackCmd = "cp -r $curSrc $SOURCE_DIR/$(stripHash $curSrc)";
        
        postUnpack = ''
            ''${GENODE_DIR}/tool/create_builddir x86_64
            cp "''${SOURCE_DIR}/$(stripHash ${buildConf})" "''${BUILD_DIR}/etc/build.conf"
        '';

        buildPhase = ''
            cd "''${BUILD_DIR}"
        ''
        + args.buildPhase + ''
            cd "''${SOURCE_DIR}"
        '';
    };
}