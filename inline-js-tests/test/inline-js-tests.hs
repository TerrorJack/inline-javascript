{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE UndecidableInstances #-}

import Control.Exception hiding (assert)
import Control.Monad
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as LBS
import Data.Foldable
import Data.String
import Foreign
import Language.JavaScript.Inline
import Language.JavaScript.Inline.Examples.Stream
import Language.JavaScript.Inline.Tests.Utils.Aeson
import Paths_inline_js_tests
import System.Directory
import System.FilePath
import System.IO
import System.IO.Temp
import System.Random.SplitMix
import Test.Tasty
import Test.Tasty.HUnit hiding (assert)
import Test.Tasty.QuickCheck

main :: IO ()
main = do
  data_dir <- getDataDir
  defaultMain $
    testGroup
      "kitchen-sink"
      [ testCase "Session: new/close" $ withDefaultSession $ \_ -> pure (),
        testCase "Session: delay" $
          withDefaultSession $ \s -> do
            vs <-
              replicateM 0x1000 $
                (eval @()) s "new Promise((resolve) => setTimeout(resolve, 1000))"
            for_ vs evaluate,
        testCase "Session: roundtrip" $
          withDefaultSession $ \s ->
            replicateM_ 0x10 $ do
              let buf = "asdf"
              buf' <- (eval @LBS.ByteString) s $ toJS buf
              buf' @?= buf,
        withResource (newSession defaultConfig) killSession $ \m ->
          testProperty "JSON" $
            forAll (V <$> genValueWithSize 0x400) $ \v ->
              ioProperty $ do
                s <- m
                v' <- eval s [js| $v |]
                pure $ v' == v,
        testCase "catch-use-after-free" $ do
          (err :: Aeson String) <-
            bracket (newSession defaultConfig) killSession $
              \s ->
                eval
                  s
                  [js| new Promise(resolve => setTimeout(resolve, 8000, "asdf")) |]
          result <- catch (False <$ evaluate err) $ \SessionClosed -> pure True
          assertBool "" result,
        withResource
          ( newSession
              defaultConfig
                { nodeModules = Just $ data_dir </> "jsbits" </> "node_modules"
                }
          )
          killSession
          $ \m -> testCase "left-pad" $ do
            s <- m
            (Aeson r :: Aeson String) <-
              eval
                s
                [js| require('left-pad')('foo', 5) |]
            r @?= "  foo",
        testCase "expr" $
          withDefaultSession $ \s -> replicateM_ 0x10 $ do
            let x = I 6
                y = I 7
            r <- eval s [js| $x * $y |]
            r @?= I 42,
        testCase "import" $
          withDefaultSession $ \s -> replicateM_ 0x10 $ do
            v <- eval s [js| (x, y) => x * y |]
            let f = importJSFunc s v
            r <- f (I 6) (I 7)
            r @?= I 42,
        testCase "export" $
          withDefaultSession $ \s -> replicateM_ 0x10 $ do
            let f :: V -> V -> IO V
                f (V x) (V y) = pure $ V $ A.Array [x, y]
            v <- export s f
            let x = V $ A.String "asdf"
                y = V $ A.String "233"
            r <- eval s [js| $v($x, $y) |]
            r @?= V (A.Array [A.String "asdf", A.String "233"])
            freeJSVal v,
        testCase "exportSync" $
          withDefaultSession $ \s -> replicateM_ 0x10 $ do
            let f :: V -> V -> IO V
                f x y = eval s [js| [$x, $y] |]
            v <- exportSync s f
            let x = V $ A.String "asdf"
                y = V $ A.String "233"
            r <- eval s [js| $v($x, $y) |]
            r @?= V (A.Array [A.String "asdf", A.String "233"])
            freeJSVal v,
        testCase "stream" $
          withDefaultSession $ \s ->
            bracket (randomFile 0x100000) removeFile $ \p -> do
              let js_path = fromString @EncodedString p
              js_stream <-
                eval
                  s
                  [js|
                    const fs = require("fs");
                    return fs.createReadStream($js_path);
                  |]
              js_content <- lazyStream s js_stream
              hs_content <- LBS.readFile p
              js_content @?= hs_content
      ]

newtype I = I Int
  deriving (Eq, Show)
  deriving (ToJS, FromJS) via (Aeson Int)

newtype V = V A.Value
  deriving (Eq, Show)
  deriving (ToJS, FromJS) via (Aeson A.Value)

withDefaultSession :: (Session -> IO a) -> IO a
withDefaultSession = withSession defaultConfig

randomFile :: Int -> IO FilePath
randomFile size = do
  tmpdir <- getCanonicalTemporaryDirectory
  (p, h) <- openBinaryTempFile tmpdir "inline-js"
  gen <- newSMGen
  alloca $ \ptr ->
    let w _gen _size
          | _size >= 8 = do
            let (x, _gen') = nextWord64 _gen
            poke ptr x
            hPutBuf h ptr 8
            w _gen' (_size - 8)
          | otherwise = pure ()
     in w gen size
  hClose h
  pure p
