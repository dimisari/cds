{-# language LambdaCase, TypeSynonymInstances, FlexibleInstances #-}

module Main where

import System.Directory qualified as D
import System.Environment qualified as E
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
    [nickname] -> write_path_to_cd_info nickname
    _ -> print "Unexpected arguments"

-- list

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
  to_pointing_str = \(nickname, (dir, _)) -> nickname ++ " -> " ++ dir

  nl_top_bottom :: String -> String
  nl_top_bottom = ("\n\n" ++) .> (++ "\n\n")

-- add

add_nickname_for_wd :: T.Nickname -> IO ()
add_nickname_for_wd = \nickname -> H.pwd >>= add_nickname nickname

add_nickname :: T.Nickname -> FilePath -> IO ()
add_nickname = \nickname dir ->
  lookup_nickname nickname >>= \case
    Nothing ->
      H.utf8_print (MAE.adding_msg nickname dir) >>
      add_nickname_tuple_to_file (nickname, (dir, 0))
    Just (old_dir, _) ->
      H.utf8_print $ MAE.name_exists_msg old_dir nickname

-- delete

delete_nickname :: T.Nickname -> IO ()
delete_nickname = \nickname ->
  lookup_nickname nickname >>= \case
    Nothing -> H.utf8_print $ MAE.nickname_does_not_exist_msg nickname
    Just (dir, _) ->
      H.utf8_print (MAE.deleting_msg nickname dir) >> remove_nickname nickname

-- write_path_to_cd_info

write_path_to_cd_info :: T.Nickname -> IO ()
write_path_to_cd_info nickname =
  lookup_nickname nickname >>= \case
    Nothing -> write_nickname_to_path_if_dir
    Just nick_name_info -> inc_counter_and_write_dir_to_path nick_name_info
  where
  write_nickname_to_path_if_dir :: IO ()
  write_nickname_to_path_if_dir =
    print (MAE.unknown_nickname_msg nickname) >>
    D.doesDirectoryExist nickname >>= \case
      True -> print MAE.is_dir_cd_msg >> save_back_and_write_cd_to_path nickname
      False -> print MAE.is_not_dir_cd_msg >> H.dont_cd

  inc_counter_and_write_dir_to_path :: T.NickNameInfo -> IO ()
  inc_counter_and_write_dir_to_path = \(dir, cd_counter) ->
    replace_nickname (nickname, (dir, cd_counter + 1)) >>
    save_back_and_write_cd_to_path dir

-- tuples from file

get_tuples :: IO [T.NickNameTuple]
get_tuples =
  H.does_nicknames_file_exist >>= \case
    True -> H.read_nicknames_file >$> file_str_to_tuples
    False -> pure []
  where
  file_str_to_tuples :: String -> [T.NickNameTuple]
  file_str_to_tuples = lines .> filter (/= "") .> map line_to_tuple

  line_to_tuple :: String -> T.NickNameTuple
  line_to_tuple =
    DLS.splitOn "," .> \case
      [nickname, dir, cd_counter] -> (nickname, (dir, read cd_counter))
      other -> error $ MAE.line_to_tuple_err ++ show other

-- tuples to file

tuples_to_file :: [T.NickNameTuple] -> IO ()
tuples_to_file = tuples_to_str .> H.write_to_nicknames_file

tuples_to_str :: [T.NickNameTuple] -> String
tuples_to_str = concatMap nickname_tuple_to_file_line

add_nickname_tuple_to_file :: T.NickNameTuple -> IO ()
add_nickname_tuple_to_file =
  nickname_tuple_to_file_line .> H.append_to_nicknames_file

nickname_tuple_to_file_line :: T.NickNameTuple -> String
nickname_tuple_to_file_line = \(nickname, (dir, cd_counter)) ->
  nickname ++ "," ++ dir ++ "," ++ show cd_counter ++ "\n"

-- nickname lookup/remove

lookup_nickname :: T.Nickname -> IO (Maybe T.NickNameInfo)
lookup_nickname = \nickname -> get_tuples >$> lookup nickname

remove_nickname :: T.Nickname -> IO ()
remove_nickname = \nickname ->
  get_tuples >$> filter (fst .> (/= nickname)) >>= tuples_to_file

replace_nickname :: T.NickNameTuple -> IO ()
replace_nickname = \tuple@(nickname, _) ->
  remove_nickname nickname >> add_nickname_tuple_to_file tuple

-- other

save_back_and_write_cd_to_path :: String -> IO ()
save_back_and_write_cd_to_path = \p ->
  replace_back_with_wd >> H.write_cd_to_path p

replace_back_with_wd :: IO ()
replace_back_with_wd = H.pwd >>= \wd -> replace_nickname ("back", (wd, 0))
