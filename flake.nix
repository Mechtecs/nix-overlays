{
  description = "Mechtecs nix overlays";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let

      systems = [ "x86_64-linux" /*"i686-linux" "aarch64-linux"*/ ];

      forAllSystems = f: lib.genAttrs systems (system: f system);

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = self.overlay;
        }
      );

      derivations = [
        "microsoft-edge-stable"
      ];

      lib = nixpkgs.lib;

    in
    {

      packages = forAllSystems (system:
        builtins.listToAttrs
          (builtins.map
            (x:
              let
                list = builtins.filter (x: builtins.typeOf x != "list") (builtins.split "\\." x);
                getPackageAttr = s: set:
                  let attr = builtins.getAttr (builtins.head s) set;
                  in
                  if builtins.tail s == [ ]
                  then attr
                  else getPackageAttr (builtins.tail s) attr;
                packageAttr = getPackageAttr list nixpkgsFor.${system}.pkgs;
                package = list:
                  if builtins.tail list == [ ]
                  then builtins.head list
                  else package (builtins.tail list);
                package' = package list;
              in
              if builtins.match ".*\\..*" x != null
              then { name = package'; value = packageAttr; }
              else { name = x; value = nixpkgsFor.${system}.pkgs.${x}; })
            derivations)
      );

      overlay = import ./overlays.nix;

    };
}

