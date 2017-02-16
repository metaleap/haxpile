{-# LANGUAGE StandaloneDeriving #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Hxp.Via.CabalSetup
(postBuild , skipBuild)
where

import Base
import qualified Dbg

import qualified Distribution.Package as CabalPkg
import qualified Distribution.PackageDescription as CabalPkgD
import qualified Distribution.Simple as CabalDst
import qualified Distribution.Simple.LocalBuildInfo as CabalBld
import qualified Distribution.Simple.Setup as CabalCfg

import qualified Data.List
import qualified System.Directory
import qualified System.Environment
import qualified System.FilePath
import qualified System.IO
import qualified System.Process



deriving instance Read CabalCfg.BuildFlags

data DumpForFrontend
    = FromCabal (Maybe CabalDst.Args) CabalCfg.BuildFlags CabalPkgD.PackageDescription CabalBld.LocalBuildInfo
    deriving (Read , Show)



postBuild :: FilePath  ->  [String]  ->  IO ()
postBuild cfgfilename ghcargs =
    CabalDst.defaultMainWithHooks CabalDst.simpleUserHooks{ CabalDst.postBuild = hook } where
    hook args buildflags pkgdesc localbuildinfo =
        let dumpforfrontend = FromCabal (Just args) buildflags pkgdesc localbuildinfo
        in invokeHook cfgfilename ghcargs dumpforfrontend
        *> (CabalDst.simpleUserHooks-:CabalDst.postBuild) args buildflags pkgdesc localbuildinfo



skipBuild :: FilePath  ->  [String]  ->  IO ()
skipBuild cfgfilename ghcargs =
    CabalDst.defaultMainWithHooks CabalDst.simpleUserHooks{ CabalDst.buildHook = hook } where
    hook pkgdesc localbuildinfo _userhooks buildflags =
        invokeHook cfgfilename ghcargs (FromCabal Nothing buildflags pkgdesc localbuildinfo)



invokeHook :: FilePath  ->  [String]  ->  DumpForFrontend  ->  IO ()
invokeHook cfgfilename userghcargs cabaldump@(FromCabal _maybeargs buildflags pkgdesc localbuildinfo) =
    System.Environment.getArgs >>= \cmdargs
    -> System.Directory.getCurrentDirectory >>= \curdir
    -> let dumpfilepath =
            curdir </> (dp $buildflags-:CabalCfg.buildDistPref) </> ".hxp" </> "cabalsetupbuildinfo.dump" where
            dp CabalCfg.NoFlag = drop 11 ("" -|= Data.List.find (Data.List.isPrefixOf "--builddir=") cmdargs)
            dp (CabalCfg.Flag dir) = dir
            _pkgname = pkgdesc-:CabalPkgD.package-:CabalPkg.pkgName-:CabalPkg.unPackageName
    in System.Directory.createDirectoryIfMissing False (System.FilePath.takeDirectory dumpfilepath)
    *> let serialized = show cabaldump
    in System.IO.writeFile dumpfilepath serialized
    *> System.IO.writeFile (dumpfilepath++".pretty") (Dbg.autoIndent serialized)
    *> let
        ghcargs = ghcCmdArgs cfgfilename dumpfilepath userghcargs ([] -|= Data.List.lookup "ghc" (buildflags-:CabalCfg.buildProgramArgs))
        ghcpath = "ghc" -|= Data.List.lookup "ghc" (localbuildinfo-:CabalBld.configFlags-:CabalCfg.configProgramPaths)
    in System.IO.hFlush System.IO.stdout
    *> System.Process.callProcess "stack" ("ghc" : "--" : ghcargs)



ghcCmdArgs :: FilePath  ->  FilePath  ->  [String]  ->  [String]  ->  [String]
ghcCmdArgs cfgfilename dumpfilepath userargs _buildflagargs =
    --  _buildflagargs is like ["-ddump-hi","-ddump-to-file"] --- unnecessary for our --frontend run
    let defargs = ["-O2","-j2"]
    in (userargs <?> defargs) ++
        ["--frontend", "Hxp.Via.Frontend", "-ffrontend-opt", cfgfilename, "-ffrontend-opt", dumpfilepath]
