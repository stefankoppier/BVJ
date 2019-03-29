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
import Linearization.Path
import Linearization.Pretty
import Compilation.Compiler
import Parsing.Syntax
import Data.Accumulator
import Compilation.CompiledUnit

compilationPhase :: Phase (CompilationUnit', ProgramPaths) CompiledUnits
compilationPhase args@Arguments{verbosity} (unit, paths) = do
    liftIO $ printInformation verbosity paths
    liftIO createWorkingDir
    ExceptT (runAsync args unit paths)

printInformation :: Verbosity -> ProgramPaths -> IO ()
printInformation verbosity paths = do
    printHeader "4. COMPILATION"
    printText $ "Compiling " ++ show (length paths) ++ " program path(s)."
    case verbosity of
        Informative -> unless (null paths) 
                            (printPretty paths)
        _           -> return ()   

runAsync :: Arguments -> CompilationUnit' -> ProgramPaths -> IO (Either PhaseError CompiledUnits)
runAsync args@Arguments{numberOfThreads} unit paths = do
    let pathsWithIndices = zip paths [0..]    
    progress <- liftIO $ progressBar (length paths)
    time     <- getCurrentDateTime
    let dir   = workingDir ++ "/" ++ timeString time ++ "/"
    createDirectory dir
    let tasks = map (\ (path, index) -> return $ compile progress unit dir index path) pathsWithIndices
    results  <- withPool numberOfThreads (\ pool -> parallel pool tasks)
    results' <- mapM runExceptT results
    putStrLn ""
    return  (sequence results')

createWorkingDir :: IO ()
createWorkingDir = do 
    createDirectoryIfMissing False workingDir
    return ()
    
timeString :: DateTime -> String
timeString DateTime{year,month,day,hour,minute,second}
    = show year ++ "_" ++ show month ++ "_" ++ show day ++ "_" 
    ++ show hour ++ "_" ++ show minute ++ "_" ++ show second