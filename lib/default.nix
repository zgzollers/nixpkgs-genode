{ pkgs, lib }: 

{
    mkGenodeSrc = { rev, ports ? [ ] }: pkgs.stdenv.mkDerivation rec {
        name = "genode-src";

        src = builtins.fetchGit {
            inherit rev;

            name = "genode";

            url = "https://github.com/genodelabs/genode.git";
        };

        buildInputs = with pkgs; [
            expect
            git
            gnumake
            wget
        ];

        patchPhase = ''
            patchShebangs --host $(find . -type f -executable)
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