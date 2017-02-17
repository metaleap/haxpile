module Main where

import Base
import qualified Lst

import qualified System.Directory
import qualified System.Environment
import qualified System.FilePath
import qualified System.IO
import qualified System.Process


data Invoke = RunGhc | PrepGhc


main :: IO ()
main =
    System.Environment.getArgs >>= \ cmdargs
    -> let
        isfromreplcmd = elem "--interactive" cmdargs
        stackghciscriptfilepath = "" -|= (drop 13 <$> Lst.find (Lst.isPrefixOf "-ghci-script=") cmdargs)
    in invokeGhc (isfromreplcmd |? PrepGhc |! RunGhc) stackghciscriptfilepath cmdargs



invokeGhc :: Invoke  ->  String  ->  [String]  ->  IO ()
invokeGhc RunGhc _ args =
    System.IO.hFlush System.IO.stdout
    *> System.Process.callProcess "ghc" args -- Stack at least ensures the right one is in %PATH%, Cabal no idea
    *> System.IO.hFlush System.IO.stdout
invokeGhc PrepGhc stackghciscriptfilepath args =
    let nuargs = (args ~|not.ditch) ++
                    ["-user-package-db","-Wall","-O2","-j4"
                    ,"--frontend","Hxp.Via.Frontend","-plugin-package","haxpile"]
        ditch arg =
            any (Lst.isPrefixed arg) ["-W","-j","-O","-ghci"] || ishxpdevenv arg ||
                elem arg ["-user-package-db","-hide-all-packages","--interactive"]
        ishxpdevenv ('-':'i':stackworkdistbuilddirpath) =
            -- -iD:\dev\hs\haxpile\.stack-work\dist\ca59d0ab\build
            Lst.isInfixOf (System.FilePath.pathSeparator : "haxpile"</>".stack-work"</>"dist") stackworkdistbuilddirpath
                && Lst.isSuffixOf (System.FilePath.pathSeparator : "build") stackworkdistbuilddirpath
        ishxpdevenv _ = False
    in moduleNames stackghciscriptfilepath >>= \modnames
    -> invokeGhc RunGhc "" (modnames ++ nuargs)



moduleNames :: String  ->  IO [String]
moduleNames "" = pure []
moduleNames ghciscriptfilepath =
    System.Directory.doesFileExist ghciscriptfilepath >>= \ isfile
    -> if not isfile then pure [] else
        readFile ghciscriptfilepath >>= \ content
        -> let keep "+" = False ; keep "-" = False ; keep _ = True
        --------`content` from -ghci-script= file sth like:
        -- :add Base Dbg Lst
        -- :add HxpT.T01_PrimAdd HxpT.T02_FacRec
        -- :module + Base Dbg Hxp.ADT Hxp.Base Hxp.ES Hxp.Via.CabalSetup Hxp.Via.Frontend HxpT.T01_PrimAdd HxpT.T02_FacRec Lst
        --------often just:
        -- :module +
        in pure$ (lines content) ~| (Lst.isPrefixOf ":module ") >>= ((keep|~) . Lst.splitOn ' ' . drop 8)
