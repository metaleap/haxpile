module Hxp.Via.Frontend
(frontendPlugin)
where

import qualified DriverPhases
import qualified GhcMonad
import qualified GhcPlugins

import qualified System.Directory
import qualified System.IO


frontendPlugin :: GhcPlugins.FrontendPlugin
frontendPlugin =
    GhcPlugins.defaultFrontendPlugin { GhcPlugins.frontend = frontend }


frontend :: [String]  ->  [(String , Maybe DriverPhases.Phase)]  ->  GhcMonad.Ghc ()
frontend flags args =
    let ($~) f a = GhcPlugins.liftIO $ f a
    in GhcPlugins.liftIO (System.Directory.getCurrentDirectory) >>= \curdir
    -> print$~ flags
    *> putStrLn$~ curdir
    *> print$~ args
    *> System.IO.hFlush$~ System.IO.stdout
