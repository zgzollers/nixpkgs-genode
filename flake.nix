{
    inputs = {
        nixpkgs.url = "nixpkgs/nixpkgs-unstable";

        # Required for the `python38` package
        nixpkgs-python.url = "nixpkgs/nixos-23.11";
    };

    outputs = { self, nixpkgs, nixpkgs-python }: let
        system = "x86_64-linux";

        callImport = path: 
            let
                f = import path;
                args = rec {
                    inherit system;

                    pkgs = import nixpkgs {
                        inherit system;

                        overlays = [
                            (final: prev: { python38 = (import nixpkgs-python { inherit system; }).python38; })
                        ];
                    };

                    lib = pkgs.lib;
                };

            in f (builtins.intersectAttrs (builtins.functionArgs f) args);
    in {
        overlays = {
            packages = final: prev: { 
                genode = self.packages.${system};
            };

            lib = final: prev: {
                lib = prev.lib // { genode = self.lib; };
            };
        };

        lib = callImport ./lib;

        packages.${system} = callImport ./pkgs;

        templates = callImport ./templates;
    };
}