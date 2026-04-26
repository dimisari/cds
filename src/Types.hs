{-# language LambdaCase, TypeSynonymInstances, FlexibleInstances #-}

module Types where

import System.Environment qualified as E
import System.Process qualified as P
import Data.List qualified as DL
import Data.List.Split qualified as DLS
import Data.ByteString qualified as BS
import Data.ByteString.UTF8 qualified as U

type PathName = String

type Nickname = String

type Dir = String

type Path = String

type NickNameInfo = (Dir, CdCounter)

type NickNameTuple = (Nickname, NickNameInfo)

type Error = String

type CdCounter = Int
