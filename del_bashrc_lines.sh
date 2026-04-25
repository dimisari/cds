#!/bin/bash

grep_out=$(grep -n bashrc_append $HOME/.bashrc)
if [[ -n "$grep_out" ]]
then
  line_num=$(echo $grep_out | cut -d ":" -f 1)
  sed -i $(( $line_num-1 )),"$line_num"d $HOME/.bashrc
fi
