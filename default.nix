{ sources ? import ./nix/sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
, ghc ? "ghc8104"
, node ? "nodejs_latest"
}:
pkgs.haskell-nix.cabalProject {
  src = pkgs.haskell-nix.haskellLib.cleanGit {
    name = "inline-js";
    src = ./.;
  };
  compiler-nix-name = ghc;
  modules = [{
    packages.inline-js-core.preBuild =
      let nodeSrc = pkgs."${node}";
      in
      ''
        substituteInPlace src/Language/JavaScript/Inline/Core/NodePath.hs --replace '"node"' '"${nodeSrc}/bin/node"'
      '';
  }];
}
