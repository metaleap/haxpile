module Hxp.Setup.Cabal where

-- import Hax.Base

import qualified Distribution.PackageDescription as CabalPkg
import qualified Distribution.Simple as Cabal
import qualified Distribution.Simple.LocalBuildInfo as CabalBld
import qualified Distribution.Simple.Setup as CabalCfg


type HookBuild =
    CabalPkg.PackageDescription -> CabalBld.LocalBuildInfo -> Cabal.UserHooks -> CabalCfg.BuildFlags -> IO ()
type HookPostBuild =
    Cabal.Args -> CabalCfg.BuildFlags -> CabalPkg.PackageDescription -> CabalBld.LocalBuildInfo -> IO ()


mainES :: IO ()
mainES =
    let hooks = Cabal.simpleUserHooks
    in Cabal.defaultMainWithHooks hooks{
            Cabal.buildHook = hookBuild (Cabal.buildHook hooks),
            Cabal.postBuild = hookPostBuild (Cabal.postBuild hooks)
        }


hookBuild :: HookBuild  ->  HookBuild
hookBuild orig pkgdesc localbuildinfo userhooks buildflags =
    putStrLn "HOOK_BUILD"
    >> orig pkgdesc localbuildinfo userhooks buildflags


hookPostBuild :: HookPostBuild -> HookPostBuild
hookPostBuild orig args buildflags pkgdesc localbuildinfo =
    putStrLn "HOOK_POSTBUILD"
    >> orig args buildflags pkgdesc localbuildinfo
