# `inline-js`: Call JavaScript from Haskell, and vice versa!

[![GitHub Actions](https://github.com/tweag/inline-js/workflows/pipeline/badge.svg?branch=master)](https://github.com/tweag/inline-js/actions?query=branch%3Amaster)
[![Gitter](https://img.shields.io/gitter/room/tweag/inline-js)](https://gitter.im/tweag/inline-js)
[![Netlify Status](https://api.netlify.com/api/v1/badges/b2320ec2-8feb-44d6-886a-8cd4728d92ad/deploy-status)](https://inline-js.netlify.app)

## Documentation

### Haddock

[Haddock documentation](https://inline-js.netlify.app) for HEAD is available.

### Adding `inline-js` as a dependency

#### `cabal`

Add a `source-repository-package` in the `cabal.project` file, see
[documentation](https://cabal.readthedocs.io/en/latest/cabal-project.html#specifying-packages-from-remote-version-control-locations)
for details.

#### `stack`

Add an `extra-deps` entry in the `stack.yaml` file, see
[documentation](https://docs.haskellstack.org/en/stable/yaml_configuration/#extra-deps)
for details.

#### `nix`

Here's an example overlay.

```nix
pkgsSelf: pkgsSuper:
let
  src = pkgsSelf.fetchFromGitHub {
    owner = "tweag";
    repo = "inline-js";
    rev = "<rev>";
    sha256 = pkgsSelf.lib.fakeSha256;
  };
in
{
  haskellPackages = pkgsSuper.haskellPackages.override {
    overrides = self: _: {
      inline-js-core = (self.callCabal2nixWithOptions "inline-js-core" src
        "--subpath inline-js-core"
        { }).overrideAttrs (_: {
        preBuild = ''
          substituteInPlace src/Language/JavaScript/Inline/Core/NodePath.hs --replace '"node"' '"${pkgsSelf.nodejs-16_x}/bin/node"'
        '';
      });
      inline-js =
        self.callCabal2nixWithOptions "inline-js" src "--subpath inline-js" { };
    };
  };
}
```

#### `haskell.nix`

See
[documentation](https://input-output-hk.github.io/haskell.nix/tutorials/source-repository-hashes)
for details.

## Implemented features

- Manage `node` sessions which run the eval server script for Haskell/JavaScript
  interop
- Evaluate expressions with `require()`/`import()` support
- Export Haskell functions to async/sync JavaScript functions
- Load third party libraries in user-specified `node_modules`
- Garbage-collected `JSVal` references in Haskell
- Support `Promise`-based async evaluation
- Type classes for Haskell/JavaScript data marshaling, with `aeson` support
- Template Haskell QuasiQuoters for lifting Haskell variables into JavaScript
  code
- Doesn't require `node` native addon or third party libraries

## Planned features

- Integrate with TypeScript compiler, generate Haskell code from TypeScript
  `.d.ts` code
- Integrate with headless browser testing frameworks like
  `playwright`/`puppeteer` for running JavaScript in browsers

## Supported versions

Supported GHC versions:

- `ghc-8.6`, tested with `ghc-8.6.5`
- `ghc-8.8`, tested with `ghc-8.8.4`
- `ghc-8.10`, tested with `ghc-8.10.5`
- `ghc-9.0`, tested with `ghc-9.0.1`

Supported platforms:

- Windows 10 x64, tested with Windows Server 2019
- Linux x64, tested with Ubuntu 20.04
- macOS x64, tested with macOS 10.15

Supported `node` versions:

- `node-v10`, minimum `v10.20.0`
- `node-v12` and later

See the [CI
config](https://github.com/tweag/inline-js/blob/master/.github/workflows/pipeline.yml)
for details.

## Contributors

[<img src="https://tweag.io/logo.png" height="65">](https://tweag.io)

`inline-js` is maintained by [Tweag I/O](https://tweag.io/).

Have questions? Need help? Tweet at [@tweagio](https://twitter.com/tweagio).
