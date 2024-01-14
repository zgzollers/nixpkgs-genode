{ pkgs, lib }: 

{
    mkGenodeSrc = { genode, repos }: pkgs.stdenv.mkDerivation {
        name = "genode-src";
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
            # Link repos to source directory
            ${
                lib.lists.foldl 
                    (cur: repo: cur + "cp -r ${repos.${repo}} ./repos/${repo}\n")
                    ""
                    (builtins.attrNames repos)
            }
        '';

        # TODO: This is much more complicated than originally anticipated. A tool needs to be created
        # to automatically patch all the port files and download the repositories separately. This is
        # because git cannot access the internet when building the derivation.

        # buildPhase = if (ports != [ ]) 
        # then ''
        #     ./tool/ports/prepare_port ${lib.lists.foldl (str: elem: str + "${elem} ") "" ports}
        # '' 
        # else "";

        installPhase = ''
            mkdir -p ''${out}
            cp -r . ''${out}
        '';
    };
}