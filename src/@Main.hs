module Main where

import Hax.Base
import qualified Data.Char


main :: IO ()
main = do
    putStrLn ("hello WORLD" >~ Data.Char.toUpper)
