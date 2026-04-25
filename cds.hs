{-# language LambdaCase, TypeSynonymInstances, FlexibleInstances #-}

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
type CdCounter = Int
type NickNameInfo = (Dir, CdCounter)
type NickNameTuple = (Nickname, NickNameInfo)

-- relative to HOME

get_cds_dir :: IO Dir
get_cds_dir = E.getEnv "HOME" >$> (++ "/.local/share/cds/")

paths_file_str :: IO String
paths_file_str = get_cds_dir >$> (++ "paths_file") >>= read_file

paths :: IO [(PathName, Path)]
paths =
  paths_file_str >$> lines >$> map split_line
  where
  split_line :: String -> (PathName, Path)
  split_line line = case DLS.splitOn "=" line of
    [path_name, path] -> (path_name, path)
    _ -> error $ paths_error line

get_path_name :: PathName -> IO Path
get_path_name path_name =
  paths >$> filter (fst .> (== path_name)) >$> \case
    [] -> error $ get_path_name_err1 path_name
    [(_, path)] -> path
    _ -> error $ get_path_name_err2 path_name

get_nicknames_file_path :: IO Path
get_nicknames_file_path = get_path_name "nns_path"

get_help_file_path :: IO Path
get_help_file_path = get_path_name "help_file"

get_add_help_file_path :: IO Path
get_add_help_file_path = get_path_name "add_help_file"

-- main
main :: IO ()
main =
  E.getArgs >>= \case
    [] -> list
    ["add", nickname] -> try_to_addwd_nickname nickname
    ["del", nickname] -> try_to_delete_nickname nickname
    ["help"] -> help
    ["inc_cd_counter", nickname] -> inc_cd_counter nickname
    args -> error $ main_err ++ show args

-- try to add/addwd/cd/delete/
try_to_add_nickname :: Nickname -> FilePath -> IO ()
try_to_add_nickname nickname dir =
  check_if_exists nickname >>= \case
    Nothing -> add_nickname nickname dir
    Just (old_dir, _) -> my_print("Nickname already exists for: " ++ old_dir)
  where
  add_nickname :: Nickname -> FilePath -> IO ()
  add_nickname nickname dir =
    my_print("\nadding " ++ dir ++ " as " ++ nickname ++ "\n\n") >>
    get_nicknames_file_path >>=
    flip append_file ("\n" ++ nickname ++ "," ++ dir ++ ",0")

try_to_addwd_nickname :: Nickname -> IO ()
try_to_addwd_nickname nickname =
  command_read_output "pwd" >$> filter (/= '\n') >>=
  try_to_add_nickname nickname

try_to_delete_nickname :: Nickname -> IO ()
try_to_delete_nickname nickname =
  get_tuples >>= \tuples ->
  case lookup nickname tuples of
    Nothing -> my_print("Nickname \"" ++ nickname ++ "\" does not exist")
    Just (dir, _) -> delete_nickname tuples nickname dir

delete_nickname :: [NickNameTuple] -> Nickname -> Dir -> IO ()
delete_nickname tuples nickname dir =
  my_print("\nDeleting " ++ nickname ++ " pointing to " ++ dir ++ "\n\n") >>
  (remove_nickname nickname tuples &> tuples_to_file)

list :: IO ()
list =
  get_tuples >>= \case
    [] -> add_help
    tuples -> tuples &> sort_most_used &> convert_to_str &> my_print
  where
  sort_most_used :: [NickNameTuple] -> [NickNameTuple]
  sort_most_used = DL.sortOn (snd .> snd) .> reverse

  convert_to_str :: [NickNameTuple] -> String
  convert_to_str = map to_pointing_str .> DL.intercalate "\n\n" .> nl_top_bottom

  to_pointing_str :: NickNameTuple -> String
  to_pointing_str (nickname, (dir, _)) = nickname ++ " -> " ++ dir

  nl_top_bottom :: String -> String
  nl_top_bottom = ("\n\n" ++) .> (++ "\n\n\n")

inc_cd_counter :: Nickname -> IO ()
inc_cd_counter nickname =
  get_tuples >>= \tuples ->
  case lookup nickname tuples of
    Nothing -> error inc_cd_counter_err
    Just (dir, cd_counter) ->
      tuples_to_file new_tuples
      where
      new_tuples :: [NickNameTuple]
      new_tuples =
        (nickname, (dir, cd_counter + 1)) : remove_nickname nickname tuples

-- tuples from/to file
get_tuples :: IO [NickNameTuple]
get_tuples =
  (get_nicknames_file_path >>= read_file) >$> file_str_to_tuples
  where
  file_str_to_tuples :: String -> [NickNameTuple]
  file_str_to_tuples = lines .> filter (/= "") .> map line_to_tuple

  line_to_tuple :: String -> NickNameTuple
  line_to_tuple =
    DLS.splitOn "," .> \case
      [nickname, dir, cd_counter] -> (nickname, (dir, read cd_counter))
      other -> error $ line_to_tuple_err ++ show other

tuples_to_file :: [NickNameTuple] -> IO ()
tuples_to_file tuples =
  (tuples &> map tuple_to_line &> unlines &> write_file "/tmp/temp") >>
  (P.callCommand =<< (("mv /tmp/temp " ++) <$> get_nicknames_file_path))
  where
  tuple_to_line :: NickNameTuple -> String
  tuple_to_line (nickname, (dir, cd_counter)) =
    nickname ++ "," ++ dir ++ "," ++ show cd_counter

-- help

help :: IO ()
help = get_path_and_print get_help_file_path

add_help :: IO ()
add_help = get_path_and_print get_add_help_file_path

get_path_and_print :: IO Path -> IO ()
get_path_and_print get_path = get_path >>= read_file >>= print

-- helpers

check_if_exists :: Nickname -> IO (Maybe NickNameInfo)
check_if_exists nickname = get_tuples >$> lookup nickname

command_read_output :: String -> IO String
command_read_output command = P.readCreateProcess (P.shell command) ""

remove_nickname :: Nickname -> [NickNameTuple] -> [NickNameTuple]
remove_nickname nickname tuples = tuples &> filter (fst .> (/= nickname))

-- to use "print" for strings instead of "putStrLn"
instance {-# OVERLAPS #-} Show String where
  show = id

(>$>) = flip (<$>)
(.>) = flip (.)
x &> f = f x

-- errors
type Error = String

main_err :: Error
main_err = "main: none of the commands was run"

line_to_tuple_err :: Error
line_to_tuple_err = "line_to_tuple: not correct format\n"

inc_cd_counter_err :: Error
inc_cd_counter_err =
  "inc_cd_counter: trying to increase counter on non existant nickname"

get_path_name_err1 :: PathName -> Error
get_path_name_err1 path_name =
  "get_path_name: didn't find path name \"" ++ path_name ++ "\""

get_path_name_err2 :: PathName -> Error
get_path_name_err2 path_name =
  "get_path_name: found path name \"" ++ path_name ++ "\" multiple times"

paths_error :: String -> Error
paths_error line =
  "paths: couldn't split nicely the following line:\n" ++ line

read_file :: Path -> IO String
read_file = BS.readFile .> fmap U.toString

write_file :: Path -> String -> IO ()
write_file = \p s -> BS.writeFile p (U.fromString s)

append_file :: Path -> String -> IO ()
append_file = \p s -> BS.appendFile p (U.fromString s)

my_print :: String -> IO ()
my_print = U.fromString .> BS.putStr
