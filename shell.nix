{ sources ? import ./nix/sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, nixpkgsSrc ? haskellNix.sources.nixpkgs-2009
, nixpkgsArgs ? haskellNix.nixpkgsArgs
, pkgs ? import nixpkgsSrc nixpkgsArgs
, ghc ? "ghc8102"
, hsPkgs ? import ./default.nix { inherit pkgs; }
}: hsPkgs.shellFor {
  packages = ps: with ps; [
    inline-js
    inline-js-core
    inline-js-examples
    inline-js-tests
  ];

  withHoogle = true;

  buildInputs = with pkgs.haskellPackages; [
    brittany
    cabal-install
    ghcid
    hlint
    pkgs.nodejs-14_x
    ormolu
    (import sources.ghcide-nix {})."ghcide-${ghc}"
  ];

  exactDeps = true;
}
