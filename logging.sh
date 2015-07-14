#!/bin/bash

##########################################################################
# library
##########################################################################

# via http://stackoverflow.com/a/12199798/18706
format_date() {
  ((h=${1}/3600))
  ((m=(${1}%3600)/60))
  ((s=${1}%60))
  printf "%02d:%02d:%02d\n" $h $m $s
}

start=$(date +"%s")
age() {
  now=$(date +"%s")
  the_age=$(($now-$start))
  format_date $the_age
}

announce() {
  echo `age`" ${FUNCNAME[ 1 ]} $1"
}

log() {
  echo -e "$(age)\t$scriptname\t $1"
}

