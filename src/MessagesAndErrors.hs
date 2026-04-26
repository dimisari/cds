module MessagesAndErrors where

import Types qualified as T

-- messages

name_exists_msg :: FilePath -> String
name_exists_msg old_dir = "Nickname already exists for: " ++ old_dir

adding_msg :: T.Nickname -> FilePath -> String
adding_msg nickname dir = "\nAdding " ++ dir ++ " as " ++ nickname ++ "\n"

unknown_nickname_msg :: String
unknown_nickname_msg =
  "\nI don't know that nickname :/\nMaybe you meant regular cd. Trying it..\n"

-- errors

main_err :: T.Error
main_err = "main: none of the commands was run"

line_to_tuple_err :: T.Error
line_to_tuple_err = "line_to_tuple: not correct format\n"

inc_cd_counter_err :: T.Error
inc_cd_counter_err =
  "get_nickname_path: trying to increase counter on non existant nickname"

dont_cd_err :: T.Error
dont_cd_err =
  "dont_cd: info path does not have 2 comma seperated values"
