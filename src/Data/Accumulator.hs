module Data.Accumulator where

import Control.Monad (ap)

newtype Accumulator a v = Accumulator { runAccumulator :: a -> (a, v) }

instance Functor (Accumulator a) where
    fmap f (Accumulator v) = Accumulator (\ a -> let (a', v') = v a
                                                  in (a', f v')) 

instance Applicative (Accumulator a) where
    pure  = return
    (<*>) = ap

instance Monad (Accumulator a) where
    return v = Accumulator (\ a -> (a, v))
    (Accumulator m) >>= f = Accumulator (\ a -> let (a', v')         = m a
                                                    (Accumulator m') = f v'
                                                 in m' a')

getAccumulator :: Accumulator a a
getAccumulator = Accumulator (\ a -> (a, a))

updateAccumulator :: (a -> a) -> Accumulator a ()
updateAccumulator f = Accumulator (\ a -> (f a, ()))