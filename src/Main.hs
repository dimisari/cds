{-# language LambdaCase, TypeSynonymInstances, FlexibleInstances #-}

module Main where

import System.Environment qualified as E
import System.Process qualified as P
import Data.List qualified as DL
import Data.List.Split qualified as DLS

import Types qualified as T
import MessagesAndErrors qualified as MAE
import Helpers ((>$>), (.>), (&>))
import Helpers qualified as H

-- main
main :: IO ()
main =
  E.getArgs >>= \case
    [] -> list >> H.dont_cd
    ["add", nickname] -> add_nickname_for_wd nickname >> H.dont_cd
    ["del", nickname] -> delete_nickname nickname >> H.dont_cd
    ["help"] -> H.print_help_file >> H.dont_cd
    [nickname] -> write_nickname_path_to_path_file nickname
    _ -> print "Unexpected arguments"

-- add

add_nickname :: T.Nickname -> FilePath -> IO ()
add_nickname nickname dir =
  check_if_exists nickname >>= \case
    Nothing -> actually_add_nickname nickname dir
    Just (old_dir, _) -> H.utf8_print $ MAE.name_exits_msg old_dir
  where
  check_if_exists :: T.Nickname -> IO (Maybe T.NickNameInfo)
  check_if_exists nickname = get_tuples >$> lookup nickname

  actually_add_nickname :: T.Nickname -> FilePath -> IO ()
  actually_add_nickname nickname dir =
    H.utf8_print (MAE.adding_msg nickname dir) >>
    H.get_nick_names_path >>=
    flip H.append_file ("\n" ++ nickname ++ "," ++ dir ++ ",0")

add_nickname_for_wd :: T.Nickname -> IO ()
add_nickname_for_wd nickname =
  H.command_read_output "pwd" >$> filter (/= '\n') >>= add_nickname nickname

-- delete

delete_nickname :: T.Nickname -> IO ()
delete_nickname nickname =
  get_tuples >>= \tuples ->
  case lookup nickname tuples of
    Nothing -> H.utf8_print("T.Nickname \"" ++ nickname ++ "\" does not exist")
    Just (dir, _) -> actually_delete_nickname tuples nickname dir

actually_delete_nickname :: [T.NickNameTuple] -> T.Nickname -> T.Dir -> IO ()
actually_delete_nickname tuples nickname dir =
  H.utf8_print("\nDeleting " ++ nickname ++ " pointing to " ++ dir ++ "\n") >>
  (remove_nickname nickname tuples &> tuples_to_file)

list :: IO ()
list =
  get_tuples >>= \case
    [] -> H.print_add_help_file
    tuples -> tuples &> sort_most_used &> convert_to_str &> H.utf8_print
  where
  sort_most_used :: [T.NickNameTuple] -> [T.NickNameTuple]
  sort_most_used = DL.sortOn (snd .> snd) .> reverse

  convert_to_str :: [T.NickNameTuple] -> String
  convert_to_str = map to_pointing_str .> DL.intercalate "\n\n" .> nl_top_bottom

  to_pointing_str :: T.NickNameTuple -> String
  to_pointing_str (nickname, (dir, _)) = nickname ++ " -> " ++ dir

  nl_top_bottom :: String -> String
  nl_top_bottom = ("\n\n" ++) .> (++ "\n\n")

write_nickname_path_to_path_file :: T.Nickname -> IO ()
write_nickname_path_to_path_file = \nickname ->
  get_tuples >>= \tuples ->
  case lookup nickname tuples of
    Nothing -> print MAE.unknown_nickname_msg >> H.cd_info_path nickname
    Just (dir, cd_counter) ->
      tuples_to_file new_tuples >> H.cd_info_path dir
      where
      new_tuples :: [T.NickNameTuple]
      new_tuples =
        (nickname, (dir, cd_counter + 1)) : remove_nickname nickname tuples

-- tuples from/to file

get_tuples :: IO [T.NickNameTuple]
get_tuples =
  (H.get_nick_names_path >>= H.read_file) >$> file_str_to_tuples
  where
  file_str_to_tuples :: String -> [T.NickNameTuple]
  file_str_to_tuples = lines .> filter (/= "") .> map line_to_tuple

  line_to_tuple :: String -> T.NickNameTuple
  line_to_tuple =
    DLS.splitOn "," .> \case
      [nickname, dir, cd_counter] -> (nickname, (dir, read cd_counter))
      other -> error $ MAE.line_to_tuple_err ++ show other

tuples_to_file :: [T.NickNameTuple] -> IO ()
tuples_to_file tuples =
  (tuples &> map tuple_to_line &> unlines &> H.write_file "/tmp/temp") >>
  (P.callCommand =<< (("mv /tmp/temp " ++) <$> H.get_nick_names_path))
  where
  tuple_to_line :: T.NickNameTuple -> String
  tuple_to_line (nickname, (dir, cd_counter)) =
    nickname ++ "," ++ dir ++ "," ++ show cd_counter

-- other

remove_nickname :: T.Nickname -> [T.NickNameTuple] -> [T.NickNameTuple]
remove_nickname nickname tuples = tuples &> filter (fst .> (/= nickname))
