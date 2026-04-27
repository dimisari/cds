{-# language LambdaCase #-}

module Helpers where

import System.Environment qualified as E
import Data.ByteString qualified as BS
import Data.ByteString.UTF8 qualified as U
import System.Process qualified as P
import Data.List.Split qualified as DLS

import Types qualified as T
import MessagesAndErrors qualified as MAE

-- operators

(>$>) = flip (<$>)
(.>) = flip (.)
x &> f = f x

-- command

pwd :: IO String
pwd = command_read_output "pwd" >$> filter (/= '\n')

command_read_output :: String -> IO String
command_read_output command =
  P.callCommand (command ++ " > /tmp/command_output") >>
  read_file "/tmp/command_output"

-- cd_info

cd_info_path :: String -> IO ()
cd_info_path = ("cd," ++) .> write_to_cd_info

dont_cd :: IO ()
dont_cd =
  get_cd_info_path >>= read_file >>= DLS.splitOn "," .> \case
    [cd, path] -> write_to_cd_info $ "dont_cd," ++ path
    [""] -> write_to_cd_info "dont_cd,"
    [] -> error MAE.dont_cd_err

write_to_cd_info :: String -> IO ()
write_to_cd_info = \str -> get_cd_info_path >>= \path -> write_file path str

-- print_help

print_help_file :: IO ()
print_help_file = get_help_file_path >>= print_file

print_add_help_file :: IO ()
print_add_help_file = get_add_help_file_path >>= print_file

-- read/write/append to nicknames file

read_nicknames_file :: IO String
read_nicknames_file = get_nicknames_path >>= read_file

write_to_nicknames_file :: String -> IO ()
write_to_nicknames_file = \str ->
  get_nicknames_path >>= \path -> write_file path str

append_to_nicknames_file :: String -> IO ()
append_to_nicknames_file = \str ->
  get_nicknames_path >>= \path -> append_file path str

-- get paths

get_cds_dir :: IO T.Dir
get_cds_dir = append_to_path (E.getEnv "HOME") "/.local/share/cds/"

get_nicknames_path :: IO T.Path
get_nicknames_path = append_to_path get_cds_dir "dir_nicknames"

get_cd_info_path :: IO T.Path
get_cd_info_path = append_to_path get_cds_dir "cd_info"

get_help_files_path :: IO T.Path
get_help_files_path = append_to_path get_cds_dir "help_files/"

get_help_file_path :: IO T.Path
get_help_file_path = append_to_path get_help_files_path "help.txt"

get_add_help_file_path :: IO T.Path
get_add_help_file_path = append_to_path get_help_files_path "add_help.txt"

append_to_path :: IO T.Path -> String -> IO T.Path
append_to_path = \get_foo str -> get_foo >$> (++ str)

-- read/write with UTF8

utf8_print :: String -> IO ()
utf8_print = (++ "\n") .> U.fromString .> BS.putStr

read_file :: T.Path -> IO String
read_file = BS.readFile .> fmap U.toString

write_file :: T.Path -> String -> IO ()
write_file = \p s -> BS.writeFile p (U.fromString s)

append_file :: T.Path -> String -> IO ()
append_file = \p s -> BS.appendFile p (U.fromString s)

print_file :: T.Path -> IO ()
print_file = read_file .> (>>= utf8_print)

-- to use "print" for strings instead of "putStrLn"

instance {-# OVERLAPS #-} Show String where
  show = id
