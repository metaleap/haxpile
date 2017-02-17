module Main where

import Base

import qualified GHC.Paths

import qualified Data.List
import qualified System.Environment
import qualified System.IO
import qualified System.Process

main :: IO ()
main =
    System.Environment.getArgs >>= \ cmdargs
    -> let
        invokehack = elem "--interactive" cmdargs
        nuargs = ["--frontend","Hxp.Via.Frontend","-plugin-package","haxpile","-ffrontend-opt","moo"] ++ (cmdargs ~|(/="--interactive") ~|(/="-hide-all-packages")) ++ ["-user-package-db"]
    in putStrLn "OY-SHIM:"
    *> print cmdargs
    *> putStrLn ("BYE-SHIM")
    *> print nuargs
    *> putStrLn ("RUN-GHC: " ++ GHC.Paths.ghc)
    *> System.IO.hFlush System.IO.stdout
    *> System.Process.callProcess GHC.Paths.ghc nuargs
    *> System.IO.hFlush System.IO.stdout
