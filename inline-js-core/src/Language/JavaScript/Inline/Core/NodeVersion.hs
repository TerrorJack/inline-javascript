{-# OPTIONS_GHC -Wno-incomplete-uni-patterns #-}

module Language.JavaScript.Inline.Core.NodeVersion
  ( checkNodeVersion,
  )
where

import Control.DeepSeq
import Control.Exception
import Control.Monad
import Data.Version
import Language.JavaScript.Inline.Core.Exception
import System.Process

split :: (a -> Bool) -> [a] -> [[a]]
split f l = case foldr w [] l of
  [] : r -> r
  r -> r
  where
    w x acc
      | f x = case acc of
        (_ : _) : _ -> [] : acc
        _ -> acc
      | otherwise = case acc of
        [] -> [[x]]
        xs : acc' -> (x : xs) : acc'

nodeVersion :: FilePath -> IO Version
nodeVersion p = do
  ('v' : s) <- readProcess p ["--version"] ""
  let vs : tags = split (== '-') s
      v = map read $ split (== '.') vs
  evaluate $ force $ Version v tags

checkNodeVersion :: FilePath -> IO ()
checkNodeVersion p = do
  v <- nodeVersion p
  unless (v >= Version [10, 12] []) $
    throwIO UnsupportedNodeVersion {detectedNodeVersion = v}
