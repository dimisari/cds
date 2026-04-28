module MessagesAndErrors where

import Types qualified as T

-- messages

name_exists_msg :: FilePath -> T.Nickname -> String
name_exists_msg = \old_dir nickname ->
  "\nNickname \"" ++ nickname ++ "\" already exists for \"" ++ old_dir ++ "\".\n"

adding_msg :: T.Nickname -> FilePath -> String
adding_msg = \nickname dir ->
  "\nAdding \"" ++ dir ++ "\" as \"" ++ nickname ++ "\".\n"

nickname_does_not_exist_msg :: T.Nickname -> String
nickname_does_not_exist_msg = \nickname ->
  "\nNickname \"" ++ nickname ++ "\" does not exist.\n"

deleting_msg :: T.Nickname -> T.Dir -> String
deleting_msg = \nickname dir ->
  "\nDeleting \"" ++ nickname ++ "\" pointing to \"" ++ dir ++ "\".\n"

unknown_nickname_msg :: T.Nickname -> String
unknown_nickname_msg = \nickname ->
  nickname_does_not_exist_msg nickname ++
  "Maybe you meant regular cd. Checking if it's a directory."

is_dir_cd_msg :: String
is_dir_cd_msg = "All good. Using regular cd.\n"

is_not_dir_cd_msg :: String
is_not_dir_cd_msg = "Looks like it's not a directory either. :/\n"

-- errors

line_to_tuple_err :: T.Error
line_to_tuple_err = "line_to_tuple: not correct format\n"

dont_cd_err :: T.Error
dont_cd_err = "dont_cd: info path does not have 2 comma seperated values"
