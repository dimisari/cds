{-# language LambdaCase, TypeSynonymInstances, FlexibleInstances #-}

module Main where

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

-- add

add_nickname :: T.Nickname -> FilePath -> IO ()
add_nickname = \nickname dir ->
  lookup_nickname nickname >>= \case
    Nothing ->
      H.utf8_print (MAE.adding_msg nickname dir) >>
      add_nickname_tuple_to_file (nickname, (dir, 0))
    Just (old_dir, _) ->
      H.utf8_print $ MAE.name_exists_msg old_dir nickname

add_nickname_for_wd :: T.Nickname -> IO ()
add_nickname_for_wd = \nickname ->
  H.command_read_output "pwd" >$> filter (/= '\n') >>= add_nickname nickname

-- delete

delete_nickname :: T.Nickname -> IO ()
delete_nickname = \nickname ->
  lookup_nickname nickname >>= \case
    Nothing -> H.utf8_print $ MAE.nickname_does_not_exist_msg nickname
    Just (dir, _) ->
      H.utf8_print (MAE.deleting_msg nickname dir) >> remove_nickname nickname

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

-- write_path_to_cd_info

write_path_to_cd_info :: T.Nickname -> IO ()
write_path_to_cd_info = \nickname ->
  lookup_nickname nickname >>= \case
    Nothing -> print MAE.unknown_nickname_msg >> H.cd_info_path nickname
    Just (dir, cd_counter) ->
      remove_nickname nickname >>
      add_nickname_tuple_to_file (nickname, (dir, cd_counter + 1)) >>
      H.cd_info_path dir

-- tuples from/to file

get_tuples :: IO [T.NickNameTuple]
get_tuples =
  H.read_nicknames_file >$> file_str_to_tuples
  where
  file_str_to_tuples :: String -> [T.NickNameTuple]
  file_str_to_tuples = lines .> filter (/= "") .> map line_to_tuple

  line_to_tuple :: String -> T.NickNameTuple
  line_to_tuple =
    DLS.splitOn "," .> \case
      [nickname, dir, cd_counter] -> (nickname, (dir, read cd_counter))
      other -> error $ MAE.line_to_tuple_err ++ show other

-- other

lookup_nickname :: T.Nickname -> IO (Maybe T.NickNameInfo)
lookup_nickname = \nickname -> get_tuples >$> lookup nickname

remove_nickname :: T.Nickname -> IO ()
remove_nickname = \nickname ->
  get_tuples >$> filter (fst .> (/= nickname)) >>= tuples_to_file

tuples_to_file :: [T.NickNameTuple] -> IO ()
tuples_to_file =
  map tuple_to_line .> unlines .> H.write_to_nicknames_file
  where
  tuple_to_line :: T.NickNameTuple -> String
  tuple_to_line = \(nickname, (dir, cd_counter)) ->
    nickname ++ "," ++ dir ++ "," ++ show cd_counter

add_nickname_tuple_to_file :: T.NickNameTuple -> IO ()
add_nickname_tuple_to_file =
  nickname_tuple_to_file_line .> H.append_to_nicknames_file

nickname_tuple_to_file_line :: T.NickNameTuple -> String
nickname_tuple_to_file_line = \(nickname, (dir, cd_counter)) ->
  nickname ++ "," ++ dir ++ "," ++ show cd_counter ++ "\n"
