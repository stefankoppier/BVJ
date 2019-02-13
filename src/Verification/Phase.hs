module Verification.Phase(
    verificationPhase
) where
    
import System.Process (readProcessWithExitCode)
import Auxiliary.Pretty
import Control.Concurrent.Async
import System.Directory
import System.IO
import Auxiliary.Phase
import Translation.Phase
import Verification.Result

verificationPhase :: Phase Programs VerificationResults
verificationPhase args@Arguments{keepOutputFiles} programs = do
    newEitherT $ printHeader "3. VERIFICATION"
    newEitherT $ printPretty programs
    results <- newEitherT $ runAsync args programs
    if keepOutputFiles
        then return ()
        else newEitherT removeWorkingDir
    return results

runAsync :: Arguments -> Programs -> IO (Either PhaseError VerificationResults)
runAsync args programs = do
    processes <- mapM (async . verify args) programs
    results <- mapM wait processes
    return $ sequence results

verify :: Arguments -> Program -> IO (Either PhaseError VerificationResult)
verify args program = do
    createDirectoryIfMissing False workingDir
    (path, handle) <- openTempFileWithDefaultPermissions workingDir "main.c"
    hPutStr handle (toString program)
    hClose handle
    (_,result,_) <- readProcessWithExitCode "cbmc" (cbmcArgs path args) ""
    runEitherT $ parseOutput result

removeWorkingDir :: IO (Either PhaseError ())
removeWorkingDir = do 
    removeDirectoryRecursive workingDir
    return $ Right ()

workingDir :: FilePath
workingDir = "tmp_verification_folder"

cbmcArgs :: FilePath -> Arguments -> [String]
cbmcArgs path args
    =  [path , "--xml-ui"]
    ++ ["--no-assertions"         | not $ enableAssertions args  ]
    ++ ["--bounds-check"          | enableArrayBoundsCheck args  ]
    ++ ["--pointer-check"         | enablePointerChecks args     ]
    ++ ["-div-by-zero-check"      | enableDivByZeroCheck args    ]
    ++ ["--signed-overflow-check" | enableIntOverflowCheck args  ]
    ++ ["--undefined-shift-check" | enableShiftCheck args        ]
    ++ ["--float-overflow-check"  | enableFloatOverflowCheck args]
    ++ ["--nan-check"             | enableNaNCheck args          ]