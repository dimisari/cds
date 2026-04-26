cds(){
  $HOME/.local/bin/cds $@
  cd_info=$(cat $HOME/.local/share/cds/cd_info)
  to_cd_or_not_to_cd=$(cut -d',' -f1 $HOME/.local/share/cds/cd_info)
  cd_path=$(cut -d',' -f2 $HOME/.local/share/cds/cd_info)
  case $to_cd_or_not_to_cd in
    "cd") cd $cd_path ;;
    "dont_cd") ;;
    *) echo "unexpect to_cd_or_not_to_cd value: $to_cd_or_not_to_cd"
  esac
}
