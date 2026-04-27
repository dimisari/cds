
CD_INFO_FILE=$HOME/.local/share/cds/cd_info

CDS_BIN=$HOME/.local/bin/cds

cds(){
  $CDS_BIN $@

  to_cd_or_not_to_cd=$(cut -d',' -f1 $CD_INFO_FILE)
  cd_path=$(cut -d',' -f2 $CD_INFO_FILE)

  case $to_cd_or_not_to_cd in
    "cd") cd $cd_path ;;
    "dont_cd") ;;
    *) echo "unexpect to_cd_or_not_to_cd value: $to_cd_or_not_to_cd"
  esac
}
