#!/bin/bash
arg=$1

if [ -n $arg ]
then
  if [ -f $arg ]
  then
    vim $arg
    exit
  elif [ -d $arg ]
  then 
    bdir=$arg
  else
    vim $arg
    exit
  fi
else
  bdir="."
fi

sessionfile=$bdir/.session.vim
if [ -f $sessionfile ]
  then
    vim -S $sessionfile
    exit
  else
    vim
    exit
fi

