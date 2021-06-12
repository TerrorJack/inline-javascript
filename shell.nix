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

  tools =
    let
      args = {
        version = "latest";
        compiler-nix-name = toolsGhc;
      };
    in
    {
      brittany = args;
      cabal-fmt = args;
      floskell = args;
      ghcid = args;
      hlint = args;
      hoogle = args;
      ormolu = args;
      stylish-haskell = args;
    };

  nativeBuildInputs = pkgs.lib.optionals ghc_pre_9 [
    (pkgs.haskell-nix.cabalProject {
      src = pkgs.fetchFromGitHub {
        owner = "haskell";
        repo = "haskell-language-server";
        rev = "7ba6279aa4b5440d110c296bd742b6e118fe63fa";
        sha256 = "sha256-zj2ht64gljpM9VfcAnJBZfLBei7XnQUkolMSkunhgTw=";
        fetchSubmodules = true;
      };
      compiler-nix-name = ghc;
      configureArgs =
        "--disable-benchmarks --disable-tests -fall-formatters -fall-plugins";
    }).haskell-language-server.components.exes.haskell-language-server
  ] ++ [
    pkgs.haskell-nix.internal-cabal-install
    pkgs.niv
    pkgs.nixfmt
    pkgs.nixpkgs-fmt
    pkgs."${node}"
  ];

  exactDeps = true;
}
