module Hxp.Via.Frontend
(frontendPlugin)
where

import Base

import qualified DriverPhases
import qualified GhcMonad
import qualified GhcPlugins

import qualified System.Directory
import qualified System.Environment
import qualified System.IO


frontendPlugin  :: GhcPlugins.FrontendPlugin
frontendPlugin  = GhcPlugins.defaultFrontendPlugin { GhcPlugins.frontend = frontend }


frontend    :: [String]  ->  [(String , Maybe DriverPhases.Phase)]
            ->  GhcMonad.Ghc ()
frontend    flags args
    =   let ($~) f a = GhcPlugins.liftIO $ f a
    in  GhcPlugins.liftIO (System.Directory.getCurrentDirectory) >>= \curdir
    ->  GhcPlugins.liftIO (System.Environment.getArgs) >>= \cmdargs
    ->  GhcPlugins.liftIO (System.Environment.lookupEnv "GHC_PACKAGE_PATH") >>= \maybestackenv
    ->  putStrLn$~ ("OY-FLAGS: " ++ show flags)
    -- *>  putStrLn$~ ("OY-GHC_PACKAGE_PATH: " ++ show maybestackenv)
    -- *>  putStrLn$~ ("OY-CUR-DIR: " ++ curdir)
    *>  putStrLn$~ ("OY-CMD-ARGS: " ++ show cmdargs)
    -- *>  putStrLn$~ ("OY-N-ARGS: " ++ show (args~>length))
    *>  putStrLn$~ ("OY-FE-ARGS: " ++ show args)
    *>  putStrLn$~ "OY-BYE!"
    *>  System.IO.hFlush$~ System.IO.stdout
