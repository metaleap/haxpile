module Hxp.Via.Frontend where

import qualified DriverPhases
import qualified GhcMonad
import qualified GhcPlugins


frontendPlugin :: GhcPlugins.FrontendPlugin
frontendPlugin =
    GhcPlugins.defaultFrontendPlugin { GhcPlugins.frontend = frontend }


frontend :: [String]  ->  [(String , Maybe DriverPhases.Phase)]  ->  GhcMonad.Ghc ()
frontend flags args =
    let ($~) f a = GhcPlugins.liftIO $ f a
    in putStrLn$~ "YAYFRONTEND"
    >> print$~ flags
    >> print$~ args
    >> putStrLn$~ "BYEFRONTEND"
