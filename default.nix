{ sources ? import ./nix/sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, nixpkgsSrc ? haskellNix.sources.nixpkgs-2009
, nixpkgsArgs ? haskellNix.nixpkgsArgs
, pkgs ? import nixpkgsSrc nixpkgsArgs
, ghc ? "ghc8102"
, node ? "nodejs-14_x"
}: pkgs.haskell-nix.cabalProject {
  src = pkgs.haskell-nix.haskellLib.cleanGit {
    name = "inline-js";
    src = ./.;
  };
  compiler-nix-name = ghc;
  modules = [{
    packages.inline-js-core.configureFlags = [
      ''--ghc-option=-DINLINE_JS_NODE=\"${builtins.getAttr node pkgs}/bin/node\"''
    ];
    packages.inline-js-tests.configureFlags = [
      ''--ghc-option=-DINLINE_JS_NPM=\"${builtins.getAttr node pkgs}/bin/npm\"''
    ];
  }];
}