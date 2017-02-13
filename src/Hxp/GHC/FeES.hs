module Hxp.GHC.FeES where

import qualified DriverPhases
import qualified GhcMonad
import qualified GhcPlugins


frontendPlugin :: GhcPlugins.FrontendPlugin
frontendPlugin =
    GhcPlugins.defaultFrontendPlugin { GhcPlugins.frontend = ecmaScript }

ecmaScript :: [String]  ->  [(String , Maybe DriverPhases.Phase)]  ->  GhcMonad.Ghc ()
ecmaScript flags args =
    let ($~) f a = GhcPlugins.liftIO $ f a
    in putStrLn$~ error$ "TODO!"
    >> print$~ flags
    >> print$~ args
