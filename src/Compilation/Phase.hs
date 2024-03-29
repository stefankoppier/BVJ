{-|
Module      : Verification.Compilation
Description : Module containing the compilation phase.
-}
module Compilation.Phase(
        compilationPhase
      , workingDir
) where

import Control.Concurrent.ParallelIO.Local
import Control.Monad
import Data.Dates
import System.Directory
import Auxiliary.Phase
import Auxiliary.Pretty
import Linearization.Pretty()
import Compilation.Compiler
import Compilation.CompiledUnit

-- | Compiles the given program paths with information from the original AST.
compilationPhase :: Phase (CompilationUnit', ProgramPaths) CompiledUnits
compilationPhase args@Arguments{verbosity} (unit, paths) = do
    liftIO $ printInformation verbosity paths
    results <- ExceptT (runAsync args unit paths)
    return [compiled | compiled@(CompiledUnit _ _) <- results]

-- | Prints information about the compilation phase to the screen.
printInformation :: Verbosity -> ProgramPaths -> IO ()
printInformation verbosity paths = do
    printHeader "4. COMPILATION"
    printText $ "Compiling " ++ show (length paths) ++ " program path(s)."
    case verbosity of
        Informative -> unless (null paths) 
                            (printPretty paths)
        _           -> return ()   

-- | Runs the compile function on the compilation units in parallel.
runAsync :: Arguments -> CompilationUnit' -> ProgramPaths -> IO (Either PhaseError CompiledUnits)
runAsync args@Arguments{numberOfThreads} unit paths = do
    let pathsWithIndices = zip paths [0..]    
    progress <- progressBar (length paths)
    time     <- getCurrentDateTime
    let dir = workingDir ++ "/" ++ timeString time ++ "/"
    createDirectory dir
    let tasks = map (\ (path, index) -> compile args progress unit dir index path) pathsWithIndices
    results  <- withPool numberOfThreads (\ pool -> parallel pool tasks)
    putStrLn ""
    return (sequence results)
    
-- | Creates a string from the given datetime.
timeString :: DateTime -> String
timeString DateTime{year,month,day,hour,minute,second}
    = show year ++ "_" ++ show month ++ "_" ++ show day ++ "_" 
    ++ show hour ++ "_" ++ show minute ++ "_" ++ show second