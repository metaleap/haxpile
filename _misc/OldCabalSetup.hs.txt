{-# LANGUAGE StandaloneDeriving #-}
{-# OPTIONS_GHC -fno-warn-orphans -fno-warn-deprecations #-}
module Hxp.Via.CabalSetup
(createShellScript , postBuild , skipBuild)
where


import Base
import qualified Dbg
import qualified Lst

import qualified Distribution.ModuleName as CabalModN
import qualified Distribution.Package as CabalPkg
import qualified Distribution.PackageDescription as CabalPkgD
import qualified Distribution.Simple as CabalDst
import qualified Distribution.Simple.LocalBuildInfo as CabalBld
import qualified Distribution.Simple.Setup as CabalCfg
import qualified Distribution.Version as CabalVer

import qualified System.Directory
import qualified System.Environment
import qualified System.FilePath
import qualified System.IO
import qualified System.Process



deriving instance Read CabalCfg.BuildFlags

data DumpForFrontend
    = FromCabal (Maybe CabalDst.Args) CabalCfg.BuildFlags CabalPkgD.PackageDescription CabalBld.LocalBuildInfo
    deriving (Read , Show)



createShellScript :: IO ()
createShellScript =
    writeFile "haxpile.bat" "stack repl --no-package-hiding --with-ghc haxpile-notarepl"
    *> CabalDst.defaultMain



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
invokeHook cfgfilename userghcargs cabaldump@(FromCabal _maybeargs buildflags pkgdesc _localbuildinfo) =
    System.Environment.getArgs >>= \cmdargs
    -> System.Environment.getEnvironment >>= \allenvs
    -> System.Directory.getCurrentDirectory >>= \curdir
    -> let
        distdir = dp $buildflags-:CabalCfg.buildDistPref where
            dp CabalCfg.NoFlag = drop 11 ("" -|= Lst.find (Lst.isPrefixOf "--builddir=") cmdargs)
            dp (CabalCfg.Flag dir) = dir
        dumpfilepath =
            curdir </> distdir </> ".hxp" </> "cabalsetupbuildinfo.dump"
    in System.Directory.createDirectoryIfMissing False (System.FilePath.takeDirectory dumpfilepath)
    *> let serialized = show cabaldump
    in System.IO.writeFile dumpfilepath serialized
    *> System.IO.writeFile (dumpfilepath++".pretty") (Dbg.autoIndent serialized)
    *> let
        ghcargs = ghcCmdArgs cfgfilename dumpfilepath (ghcDynArgs distdir allenvs (pkgdesc-:CabalPkgD.library)) userghcargs
        -- ghcpath = "ghc" -|= Lst.lookup "ghc" (localbuildinfo-:CabalBld.configFlags-:CabalCfg.configProgramPaths)
    in System.IO.hFlush System.IO.stdout
    *> print ghcargs
    *> System.IO.hFlush System.IO.stdout
    -- *> System.Process.callProcess "stack" ("ghc" : "--ghc-package-path" : "--" : ghcargs)
    *> System.IO.hFlush System.IO.stdout



ghcCmdArgs :: FilePath  ->  FilePath  ->  [String]  ->  [String]  ->  [String]
ghcCmdArgs cfgfilename dumpfilepath dynargs userargs =
    let defargs = ["-O2", "-j4"]
    in dynargs ++ (userargs <?> defargs) ++
        ["--frontend" , "Hxp.Via.Frontend", "-plugin-package", "haxpile", "-ffrontend-opt", show (cfgfilename, dumpfilepath)]


ghcDynArgs ::  String  ->  [(String,String)]  ->  (Maybe CabalPkgD.Library)  ->  [String]
ghcDynArgs _ _ Nothing =
    error "There is no `library` in this .cabal project?"
ghcDynArgs distdir env (Just lib) =
    --  distdir   ~=~   .stack-work\dist\ca59d0ab
    modnames ++ pkgdbs ++ incdirs ++ libdirs ++ deppkgs ++ idirs ++ [dist "stubdir" (distdir</>"build")] ++
        if not (Lst.isPrefixOf ".stack-work" distdir) then [] else
            [dist "odir" (".stack-work"</>"odir") , dist "hidir" (".stack-work"</>"odir")]
    where
    -- _pkgname = pkgdesc-:CabalPkgD.package-:CabalPkg.pkgName-:CabalPkg.unPackageName
    libbld = lib-:CabalPkgD.libBuildInfo
    dist argname dir = ('-' : argname) ++ ('=' : dir)
    modnames = lib-:CabalPkgD.exposedModules >~ (Lst.join '.') . CabalModN.components
    incdirs = libbld-:CabalPkgD.includeDirs >~ ("-I"++)
    libdirs = libbld-:CabalPkgD.extraLibDirs >~ ("-L"++)
    deppkgs = libbld-:CabalPkgD.targetBuildDepends >~ ("-package-id="++).showdeppkg
    pkgdbs = pkgdirs >~ ("-package-db"++)
    pkgdirs = Lst.lookup "HASKELL_PACKAGE_SANDBOXES" env ~> ((Lst.splitOn System.FilePath.searchPathSeparator) =|- []) ~|has
    idirs = ( (distdir </> "build") : (distdir </> "build" </> "autogen") :
                libbld-:CabalPkgD.hsSourceDirs ) >~ ("-i"++)

    showdepver ver = Lst.join '.' (ver-:CabalVer.versionBranch >~ show)
    showdepverr (CabalVer.IntersectVersionRanges _ (CabalVer.ThisVersion ver)) = showdepver ver
    showdepverr _ = error "New pattern-case for Cabal's version-range madness required, please report!"
    showdeppkg (CabalPkg.Dependency pkgname verrange) =
        pkgname-:CabalPkg.unPackageName ++ "-" ++ showdepverr verrange




-- _testargs = [   "-odir=D:\\dev\\hs\\haxpile-apptests\\.stack-work\\odir"
--             ,   "-hidir=D:\\dev\\hs\\haxpile-apptests\\.stack-work\\odir"
--             ,   "-iD:\\dev\\hs\\haxpile-apptests\\.stack-work\\dist\\ca59d0ab\\build\\autogen"
--             ,   "-iD:\\dev\\hs\\haxpile-apptests\\.stack-work\\dist\\ca59d0ab\\build"
--             ,   "-stubdir=D:\\dev\\hs\\haxpile-apptests\\.stack-work\\dist\\ca59d0ab\\build"
--             ,   "-iD:\\dev\\hs\\haxbase\\src"
--             ,   "-iD:\\dev\\hs\\haxbase\\.stack-work\\dist\\ca59d0ab\\build\\autogen"
--             ,   "-iD:\\dev\\hs\\haxbase\\.stack-work\\dist\\ca59d0ab\\build"
--             ,   "-stubdir=D:\\dev\\hs\\haxbase\\.stack-work\\dist\\ca59d0ab\\build"
--             ,   "-IC:\\Users\\roxor\\AppData\\Local\\Programs\\stack\\x86_64-windows\\msys2-20150512\\mingw64\\include"
--             ,   "-LC:\\Users\\roxor\\AppData\\Local\\Programs\\stack\\x86_64-windows\\msys2-20150512\\mingw64\\lib"
--             ,   "-package-id=base-4.9.1.0"
--             ,   "-package-id=filepath-1.4.1.1"
--             ,   "-iD:\\dev\\hs\\haxpile-apptests\\src"
--             ,   "-iD:\\dev\\hs\\haxpile\\src"
--             ,   "-iD:\\dev\\hs\\haxpile\\.stack-work\\dist\\ca59d0ab\\build\\autogen"
--             ,   "-stubdir=D:\\dev\\hs\\haxpile\\.stack-work\\dist\\ca59d0ab\\build"
--             ,   "-package-id=Cabal-1.24.2.0"
--             ,   "-package-id=directory-1.3.0.0"
--             ,   "-package-id=ghc-8.0.2"
--             ,   "-package-id=process-1.4.3.0"
--             ]
