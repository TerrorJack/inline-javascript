module Language.JavaScript.Inline.Tests.Utils.Aeson
  ( genValueWithSize,
  )
where

import qualified Data.Aeson as A
import GHC.Exts
import qualified Test.QuickCheck as Q
import Test.QuickCheck.Instances ()

genValueWithSize :: Int -> Q.Gen A.Value
genValueWithSize n
  | n > 1 = do
    ns <- genSplitSizes n
    Q.oneof
      [ A.Object . fromList
          <$> sequence
            [(,) <$> Q.arbitrary <*> genValueWithSize n' | n' <- ns],
        A.Array . fromList <$> sequence [genValueWithSize n' | n' <- ns]
      ]
  | n == 1 =
    Q.oneof
      [ A.String <$> Q.arbitrary,
        A.Number <$> Q.arbitrary,
        A.Bool <$> Q.arbitrary,
        pure A.Null
      ]
  | otherwise = error $ "genValueWithSize: invalid size " <> show n

genSplitSizes :: Int -> Q.Gen [Int]
genSplitSizes = w []
  where
    w acc r = do
      n' <- Q.choose (1, r)
      if n' == r then pure (n' : acc) else w (n' : acc) (r - n')
