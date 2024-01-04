{
    inputs = {
        nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    };

    outputs = { self, nixpkgs }: let
        system = "x86_64-linux";

        callImport = path: 
            let
                f = import path;
                args = rec {
                    inherit system;

                    pkgs = import nixpkgs {
                        inherit system;
                    };

                    lib = pkgs.lib;
                };

            in f (builtins.intersectAttrs (builtins.functionArgs f) args);
    in {
        overlays.default = final: prev: self.packages.${system};

        lib = callImport ./lib;

        packages.${system} = callImport ./pkgs;

        templates = callImport ./templates;
    };
}