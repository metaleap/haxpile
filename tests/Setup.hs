import Distribution.Simple

import qualified System.Environment


main =
    System.Environment.getArgs >>= \cmdargs
    -> putStrLn "GOGOGO:"
    >> putStrLn "================"
    >> defaultMain
    >> putStrLn ">>>>>>>>>>>>>>>>"
    >> print cmdargs
    >> putStrLn "<<<<<<<<<<<<<<<<"
