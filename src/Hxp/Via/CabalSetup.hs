module Hxp.Via.CabalSetup
(ensureHxpFiles)
where

import qualified System.Directory

import qualified Distribution.Simple as CabalDst


ensureHxpFiles :: IO ()
ensureHxpFiles
    = ensureShellScriptFile *> ensureHxpConfigFile *> CabalDst.defaultMain


ensureHxpConfigFile :: IO ()
ensureHxpConfigFile
    = System.Directory.doesFileExist "default.hxp" >>= \ isfile
    -> if isfile then pure () else
        writeFile "default.hxp" "default config goes here"


ensureShellScriptFile :: IO ()
ensureShellScriptFile
    = System.Directory.doesFileExist "haxpile.bat" >>= \ isfile
    -> if isfile then pure () else
        writeFile "haxpile.bat" "stack repl --no-package-hiding --with-ghc haxpile-notarepl"
