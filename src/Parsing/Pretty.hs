{-|
Module      : Parsing.Pretty
Description : Pretty instances of the data types declared in Parsing.Syntax.

This module contains the Pretty instances of the data types declared in Parsing.Syntax.

The Pretty instances generate compilable strings.
-}
module Parsing.Pretty where

import Text.PrettyPrint
import Auxiliary.Phase
import Auxiliary.Pretty

--------------------------------------------------------------------------------
-- Files
--------------------------------------------------------------------------------

instance Pretty CompilationUnit' where
    pretty (CompilationUnit' package imports decls)
        = package' $+$ pretty imports $+$ pretty decls
        where
            package' = maybe empty (\ name -> text "package" <+> dots name <> semi) package

instance Pretty ImportDecls' where
    pretty = foldr (($+$) . pretty) empty

instance Pretty ImportDecl' where
    pretty (ImportDecl' _ name everything)
        = text "import" <+> dots name <> everything' <> semi
        where
            everything'
                | everything = ".*"
                | otherwise  = empty

--------------------------------------------------------------------------------
-- Declarations
--------------------------------------------------------------------------------

instance Pretty TypeDecls' where
    pretty = foldr (($+$) . pretty) empty

instance Pretty TypeDecl' where
    pretty (ClassTypeDecl' decl) = pretty decl

instance Pretty ClassDecl' where
    pretty (ClassDecl' ms name body) = pPre $+$ pHeader $+$ pBody
        where
            (pre, inline) = preAndInlineModifiers ([], []) ms
            pPre          = foldr (($+$) . pretty) empty pre
            pHeader       = pretty inline <+> text "class" <+> text name
            pBody         = lbrace $+$ tab (pretty body) $+$ rbrace

instance Pretty Decls' where
    pretty = foldr (($+$) . pretty) empty

instance Pretty Decl' where
    pretty (MemberDecl' decl) = pretty decl

instance Pretty MemberDecl' where
    pretty (FieldDecl' modifiers ty var) 
        = pPre $+$ pretty inline <+> pretty ty <+> pretty var <> semi
        where
            (pre, inline) = preAndInlineModifiers ([], []) modifiers
            pPre          = foldr (($+$) . pretty) empty pre

    pretty (MethodDecl' modifiers ty name params body)
        = pPre $+$ pHeader $+$ pBody
        where
            (pre, inline) = preAndInlineModifiers ([], []) modifiers
            pPre          = foldr (($+$) . pretty) empty pre
            pHeader       = pretty inline <+> pretty ty <+> pretty name <> parens (pretty params)
            pBody         = lbrace $+$ tab (pretty body) $+$ rbrace

    pretty (ConstructorDecl' modifiers name params body) 
        = pPre $+$ pHeader $+$ pBody
        where
            (pre, inline) = preAndInlineModifiers ([], []) modifiers
            pPre          = foldr (($+$) . pretty) empty pre
            pHeader       = pretty inline <+> pretty name <> parens (pretty params)
            pBody         = lbrace $+$ tab (pretty body) $+$ rbrace

instance Pretty [FormalParam'] where
    pretty = commas

instance Pretty FormalParam' where
    pretty (FormalParam' modifiers ty name) 
        = pretty modifiers <+> pretty ty <+> pretty name

-- | Splits the given modifiers in two sets, the first set are defined before the
-- element and the second set are defined on the same line.
preAndInlineModifiers :: (Modifiers', Modifiers') -> Modifiers' -> (Modifiers', Modifiers')
preAndInlineModifiers acc []
    = acc
preAndInlineModifiers (l1, l2) (m@(Annotation' _):ms)
    = preAndInlineModifiers (l1 ++ [m], l2) ms
preAndInlineModifiers (l1, l2) (m:ms)
    = (l1, l2 ++ (m:ms))
        
--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

instance Pretty (Maybe Type') where
    pretty (Just ty) = pretty ty
    pretty Nothing   = text "void"

instance Pretty Type' where
    pretty (PrimType' ty) = pretty ty
    pretty (RefType' ty)  = pretty ty

instance Pretty PrimType' where
    pretty BooleanT' = text "bool"
    pretty ByteT'    = text "byte"
    pretty ShortT'   = text "short"
    pretty IntT'     = text "int"
    pretty LongT'    = text "long"
    pretty CharT'    = text "char"
    pretty FloatT'   = text "float"
    pretty DoubleT'  = text "double"

instance Pretty RefType' where
    pretty (ClassRefType' ty) = pretty ty 
    pretty (ArrayType'    ty) = pretty ty <> brackets empty

instance Pretty ClassType' where
    pretty (ClassType' ty) = dots ty

--------------------------------------------------------------------------------
-- Statements
--------------------------------------------------------------------------------

instance Pretty CompoundStmts' where
    pretty []     
        = empty

    pretty (stat:stats) 
        = pretty stat $+$ pretty stats

instance Pretty CompoundStmt' where
    pretty (Block' Nothing s)                
        = lbrace $+$ nest 4 (pretty s) $+$ rbrace
    pretty (Block' (Just ident) s)                
        = text ident <> colon <+> lbrace $+$ nest 4 (pretty s) $+$ rbrace
    pretty (IfThenElse' g s1 s2)     
        = text "if" <+> parens (pretty g) $+$ pretty s1 $+$ text "else" $+$  pretty s2
    pretty (While' ident g s)      
        = pIdent ident <+> text "while" <+> parens (pretty g) $+$ pretty s
    pretty (For' ident init guard update body)
        = pIdent ident <+> text "for" <> parens (pForInit init <+> pretty guard <> semi <+> pForUpdate update) $+$ pretty body
    pretty (Switch' e cs)            
        = text "switch" <+> parens (pretty e) $+$ lbrace $+$ pretty cs $+$ rbrace
    pretty (Try' stat catches Nothing)
        = text "try" $+$ lbrace $+$ tab (pretty stat) $+$ rbrace $+$ pretty catches 
    pretty (Try' stat catches (Just finally))
        = text "try" $+$ lbrace $+$ tab (pretty stat) $+$ rbrace $+$ pretty catches
          $+$ text "finally" $+$ lbrace $+$ tab (pretty finally) $+$ rbrace 
    pretty (Stmt' s)
        = pretty s

instance Pretty ForInit' where
    pretty (ForLocalVars' modifiers ty decls)
        = pretty modifiers <+> pretty ty <+> pretty decls
    pretty (ForInitExps' exps)
        = commas exps

-- | Pretty print a for init.
pForInit :: MaybeForInit' -> Doc
pForInit Nothing     = semi
pForInit (Just init) = pretty init <> semi

-- | Pretty print a for update.
pForUpdate :: MaybeExps' -> Doc
pForUpdate Nothing     = empty
pForUpdate (Just exps) = commas exps

-- | Pretty print an identifier.
pIdent :: Maybe String -> Doc
pIdent Nothing      = empty
pIdent (Just ident) = text ident <+> char ':'

instance Pretty Stmt' where
    pretty (Decl' ms ty vars)        = pretty ms <+> pretty ty <+> pretty vars <> semi
    pretty Empty'                    = semi
    pretty (ExpStmt' exp)            = pretty exp <> semi
    pretty (Assert' exp Nothing)     = text "assert" <+> pretty exp <> semi
    pretty (Assert' exp (Just mssg)) = text "assert" <+> pretty exp <+> colon <+> pretty mssg <> semi
    pretty (Assume' exp)             = text "CProver.assume" <> parens (pretty exp) <> semi
    pretty (Break' (Just ident))     = text "break:" <+> text ident <> semi
    pretty (Break' Nothing)          = text "break" <> semi
    pretty (Continue' (Just ident))  = text "continue:" <+> text ident <> semi
    pretty (Continue' Nothing)       = text "continue" <> semi
    pretty (Return' Nothing)         = text "return" <> semi
    pretty (Return' (Just exp))      = text "return" <+> pretty exp <> semi
    pretty (Throw' exp)              = text "throw" <+> pretty exp <> semi

instance Pretty SwitchBlocks' where
    pretty = foldr (($+$) . pretty) empty

instance Pretty SwitchBlock' where
    pretty (SwitchBlock' (Just e) stat) = text "case" <+> pretty e <> colon $+$ nest 4 (pretty stat)
    pretty (SwitchBlock' Nothing stat)  = text "default:" $+$ nest 4 (pretty stat)

instance Pretty Catches' where
    pretty = foldr (($+$) . pretty) empty

instance Pretty Catch' where
    pretty (Catch' exception body)
        = text "catch" <+> parens (pretty exception) 
        $+$ lbrace $+$ tab (pretty body) $+$ rbrace

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

instance Pretty [VarDecl'] where
    pretty = hcat . punctuate (comma <> space) . map pretty

instance Pretty VarDecl' where
    pretty (VarDecl' id init) = pretty id <> equals <> pretty init
    
instance Pretty VarDeclId' where
    pretty (VarId' id) = text id

instance Pretty VarInit' where
    pretty (InitExp' exp)     = pretty exp
    pretty (InitArray' inits) = pretty inits

instance Pretty MaybeVarInits' where
    pretty (Just es) = braces (commas es)
    pretty Nothing   = empty

--------------------------------------------------------------------------------
-- Expressions
--------------------------------------------------------------------------------

instance Pretty Exp' where
    pretty (Lit' x)                    = pretty x
    pretty This'                       = text "this"
    pretty (InstanceCreation' ty args) = text "new" <+> pretty ty <> parens (commas args)
    pretty (ArrayCreate' ty ss n)      = text "new" <+> pretty ty <> (hcat . map (brackets . pretty)) ss <> hcat (replicate n (brackets empty))
    pretty (ArrayCreateInit' ty ds is) = text "new" <+> pretty ty <> hcat (replicate ds (brackets empty)) <+> braces (commas is)
    pretty (FieldAccess' access)       = pretty access
    pretty (MethodInv' inv)            = pretty inv
    pretty (ArrayAccess' n es)         = text n <> (hcat . map (brackets . pretty)) es
    pretty (ExpName' n)                = (hcat . punctuate dot . map text) n
    pretty (PostIncrement' e)          = pretty e <> text "++"
    pretty (PostDecrement' e)          = pretty e <> text "--"
    pretty (PreIncrement' e)           = text "++" <> pretty e
    pretty (PreDecrement' e)           = text "--" <> pretty e
    pretty (PrePlus' e)                = char '+' <> pretty e
    pretty (PreMinus' e)               = char '-' <> pretty e
    pretty (PreBitCompl' e)            = char '~' <> pretty e
    pretty (PreNot' e)                 = char '!' <> pretty e
    pretty (BinOp' e1 op e2)           = parens (pretty e1 <> pretty op <> pretty e2)
    pretty (Cond' g e1 e2)             = pretty g <> char '?' <> pretty e1 <> char ':' <> pretty e2
    pretty (Assign' t op e)            = pretty t <> pretty op <> pretty e

instance Pretty Literal' where
    pretty (Int' x)         = text $ show x
    pretty (Float' x)       = float x
    pretty (Double' x)      = float x
    pretty (Boolean' True)  = text "true"
    pretty (Boolean' False) = text "false"
    pretty (Char' x)        = quotes $ char x
    pretty (String' x)      = doubleQuotes $ text x 
    pretty Null'            = text "null"

instance Pretty Op' where
    pretty Mult'    = text "*"
    pretty Div'     = text "/"
    pretty Rem'     = text "%"
    pretty Add'     = text "+"
    pretty Sub'     = text "-"
    pretty LShift'  = text "<<"
    pretty RShift'  = text ">>"
    pretty RRShift' = text ">>>"
    pretty LThan'   = text "<"
    pretty GThan'   = text ">"
    pretty LThanE'  = text "<="
    pretty GThanE'  = text ">="
    pretty Equal'   = text "=="
    pretty NotEq'   = text "!="
    pretty And'     = text "&"
    pretty Or'      = text "|"
    pretty Xor'     = text "^"
    pretty CAnd'    = text "&&"
    pretty COr'     = text "||"

instance Pretty AssignOp' where
    pretty EqualA'   = equals
    pretty MultA'    = text "*="
    pretty DivA'     = text "/="
    pretty RemA'     = text "%="
    pretty AddA'     = text "+="
    pretty SubA'     = text "-="
    pretty LShiftA'  = text "<<="
    pretty RShiftA'  = text ">>="
    pretty RRShiftA' = text ">>>="
    pretty AndA'     = text "&="
    pretty XorA'     = text "^="
    pretty OrA'      = text "|="

instance Pretty Lhs' where
    pretty (Name'  name)   = dots name
    pretty (Field' access) = pretty access
    pretty (Array' array)  = pretty array

instance Pretty ArrayIndex' where
    pretty (ArrayIndex' array indices)
        = pretty array <> indices'
        where
            indices' = foldr (\ index -> (<+>) (brackets (pretty index))) empty indices

instance Pretty FieldAccess' where
    pretty (PrimaryFieldAccess' exp field)
        = pretty exp <> dot <> text field

    pretty (ClassFieldAccess' ty field)
        = dots ty <> dot <> text field

instance Pretty MethodInvocation' where
    pretty (MethodCall' name args) = name' <> parens args'
        where
            name' = dots name
            args' = commas args

    pretty (PrimaryMethodCall' exp name args) 
        = exp' <> dot <> text name <> parens args'
        where
            exp'  = pretty exp
            args' = commas args

--------------------------------------------------------------------------------
-- Miscellaneous
--------------------------------------------------------------------------------

instance Pretty [Modifier'] where
    pretty = hcat . punctuate space . map pretty

instance Pretty Modifier' where
    pretty Public'         = text "public"
    pretty Private'        = text "private"
    pretty Protected'      = text "protected"
    pretty Abstract'       = text "abstract"
    pretty Final'          = text "final"
    pretty Static'         = text "static"
    pretty StrictFP'       = text "strictfp"
    pretty Transient'      = text "transient"
    pretty Volatile'       = text "volatile"
    pretty (Annotation' a) = pretty a
    pretty Synchronized'   = text "synchronized"

instance Pretty Annotation' where
    pretty (NormalAnnotation' name values)
        = char '@' <> dots name <> parens (pretty values)

    pretty (SingleElementAnnotation' name value)
        = char '@' <> dots name <> parens (pretty value)

    pretty (MarkerAnnotation' name)
        = char '@' <> dots name

instance Pretty AnnotationKeyValues' where
    pretty = commas

instance Pretty AnnotationKeyValue' where
    pretty (key, value)
        = pretty key <+> char '=' <+> pretty value

instance Pretty ElementValue' where
    pretty (ElementValue' init) 
        = pretty init

    pretty (ElementAnnotation' annotation)
        = pretty annotation
        
instance Pretty Scope where
    pretty (Scope scopePackage scopeClass scopeMember)
        = maybe empty (const (package' <> dot)) scopePackage <> dots [class', member']
        where
            package' = maybe empty dots scopePackage
            class'   = text scopeClass
            member'  = text scopeMember