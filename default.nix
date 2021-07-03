{ sources ? import ./nix/sources.nix { }
, haskellNix ? import
    ((import sources.nixpkgs { }).applyPatches {
      name = "haskell-nix";
      src = sources.haskell-nix;
      patches = [ ./nix/haskell-nix.patch ];
    })
    { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
, ghc ? "ghc8105"
, node ? "nodejs_latest"
}:
pkgs.haskell-nix.cabalProject {
  src = pkgs.haskell-nix.haskellLib.cleanGit {
    name = "inline-js";
    src = ./.;
  };
  compiler-nix-name = ghc;
  modules = [
    { dontPatchELF = false; }
    { dontStrip = false; }
    {
      packages.inline-js-core.preConfigure =
        let nodeSrc = pkgs."${node}";
        in
        ''
          substituteInPlace src/Language/JavaScript/Inline/Core/NodePath.hs --replace '"node"' '"${nodeSrc}/bin/node"'
        '';
    }
    { packages.inline-js-tests.testFlags = [ "-j$NIX_BUILD_CORES" ]; }
  ];
}
