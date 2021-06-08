{ sources ? import ./nix/sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
, ghc ? "ghc8105"
, toolsGhc ? "ghc8105"
, node ? "nodejs_latest"
, hsPkgs ? import ./default.nix { inherit pkgs ghc node; }
}:
let
  ghc_ver = pkgs.haskell-nix.compiler."${ghc}".version;
  ghc_pre_9 = !(pkgs.lib.versionAtLeast ghc_ver "9");
in
hsPkgs.shellFor {
  packages = ps:
    with ps; [
      inline-js
      inline-js-core
      inline-js-examples
      inline-js-tests
    ];

  withHoogle = ghc_pre_9;

  nativeBuildInputs = pkgs.lib.attrValues
    (pkgs.haskell-nix.tools toolsGhc {
      brittany = "latest";
      cabal-fmt = "latest";
      floskell = "latest";
      ghcid = "latest";
      hlint = "latest";
      ormolu = "latest";
      stylish-haskell = "latest";
    }) ++ pkgs.lib.optionals ghc_pre_9 [
    (pkgs.haskell-nix.cabalProject {
      src = pkgs.fetchFromGitHub {
        owner = "haskell";
        repo = "haskell-language-server";
        rev = "ghcide-v1.3.0";
        sha256 = "07b8xjjsd5g4lh9c1klak7gnlss5zwb6dad2cgdxry9jhx7w4z7m";
        fetchSubmodules = true;
      };
      compiler-nix-name = ghc;
      configureArgs = "--disable-benchmarks --disable-tests -fall-formatters -fall-plugins";
    }).haskell-language-server.components.exes.haskell-language-server
  ] ++ [
    pkgs.haskell-nix.internal-cabal-install
    (import sources.niv { }).niv
    pkgs.nixfmt
    pkgs.nixpkgs-fmt
    pkgs."${node}"
  ];

  exactDeps = true;
}
