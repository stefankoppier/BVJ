module Analysis.CFG where

import Data.Maybe
import Parsing.Syntax
import Data.Graph.Inductive.Graph    
import Data.Graph.Inductive.PatriciaTree    

instance {-# OVERLAPS #-} Eq (LNode a) where
    (x,_) == (y,_) = x == y

instance {-# OVERLAPS #-} Ord (LNode a) where
    (x,_) <= (y,_) = x <= y

--------------------------------------------------------------------------------
-- Control Flow Graph
--------------------------------------------------------------------------------

data CFGNodeValue 
    = StatNode        CompoundStmt'  -- ^ The statement of the node.
    | ForInitNode     ForInit'       -- ^ The for loop init of the node.
    | ForUpdateNode   Exps'          -- ^ The for loop update of the node.
    | CatchNode       Catch'         -- ^ The catch of the node.
    | FinallyNode     CompoundStmts' -- ^ The finally of the node.
    | CallNode        Scope          -- ^ The method that is being called.
                      Node           -- ^ The node containing the statement this call belongs to.
                      Name'          -- ^ The method invocation this call belongs to.
    | MethodEntryNode Scope          -- ^ The method that this entry belongs to.
    | MethodExitNode  Scope          -- ^ The method that this exit belongs to.
    deriving (Show, Eq)
    
type CFGNode = LNode CFGNodeValue

type CFGNodes = [CFGNode]

data CFGEdgeValue
    = InterEdge           Scope
    | IntraEdge       
    | BlockEntryEdge      BlockEntryType
    | BlockExitEdge       BlockEntryType
    | BlockExitsEdge      [BlockEntryType]
    | BlockExitEntryEdge  BlockEntryType 
                          BlockEntryType
    deriving (Show, Eq)

data BlockEntryType
    = TryEntryType
    | CatchEntryType       (Maybe FormalParam')
    | ConditionalEntryType (Maybe Exp')
    | FinallyEntryType
    | BlockEntryType       (Maybe String)
    deriving (Show)

instance Eq BlockEntryType where
    TryEntryType             == TryEntryType             = True
    (CatchEntryType _)       == (CatchEntryType _)       = True
    (ConditionalEntryType _) == (ConditionalEntryType _) = True
    FinallyEntryType         == FinallyEntryType         = True
    (BlockEntryType _)       == (BlockEntryType _)       = True
    _                        == _                        = False

type CFGEdge = LEdge CFGEdgeValue

type CFGEdges = [CFGEdge]

type CFGAdj = Adj CFGEdgeValue

type CFGContext = (CFGAdj, Node, CFGNodeValue, CFGAdj)

newtype CFG = CFG { cfg :: Gr CFGNodeValue CFGEdgeValue }

constructCFG :: CFGNodes -> CFGEdges -> CFG
constructCFG ns es = (CFG . insEdges es . insNodes ns) empty

entryOfMethod :: Scope -> CFG -> Maybe CFGNode
entryOfMethod method CFG{cfg}
    | [entry'] <- entry = Just (entry', fromJust $ lab cfg entry')
    | otherwise = Nothing
    where
        entry = nodes $ labfilter (\case (MethodEntryNode scope) 
                                            -> scope == method
                                         _  -> False) cfg

isIntraEdge :: CFGEdgeValue -> Bool
isIntraEdge IntraEdge                = True
isIntraEdge (BlockEntryEdge _)       = True
isIntraEdge (BlockExitEdge _)        = True
isIntraEdge (BlockExitsEdge _)       = True
isIntraEdge (BlockExitEntryEdge _ _) = True
isIntraEdge (InterEdge _)            = False

isInterEdge :: CFGEdgeValue -> Bool
isInterEdge = not . isIntraEdge