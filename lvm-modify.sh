#/bin/bash

###############
#
# LVM set up script for scanner machines
# 
##################

# device string of disk to add to LVM
#devstring="/dev/sdb"

######### Colors ############
INFO='\033[1;32m'
ALERT='\033[1;33m'
WARN='\033[1;31m'
USERINPUT='\033[1;35m'
NOCOLOR='\033[0m'
##########################
##### utility fuNOCOLORtions ###########
cont_prompt () {
  printf "${ALERT}Press [ENTER] to continue, [ctrl-c] to quit.${NOCOLOR}"
  read junk
}

printinfo () {
  printf "${INFO}$1${NOCOLOR}"
}

printwarning () {
  printf "${WARN}$1${NOCOLOR}"
  cont_prompt
}

raise_error () {
  printf "${WARN}The last command exited non-zero. Please find out what happened and try again.\n${NOCOLOR}" 
  printf "${WARN}Press [ENTER] to continue anyway or [ctrl-c] to quit and fix the problem.\n${NOCOLOR}"
  read junk
}

detect_error () {
  if [ $? -ne 0 ]
    then
      raise_error
fi
}
###################################

############# lv_extend function ####################
lv_extend () {
  # first establish a baseline. How big is / now?
  clear
  df -h
  printinfo "Take note of the size of / before we get started.\n"
  cont_prompt
  clear

  # Get the device to be added to the volume group
  printinfo "Listing partitions. This will fail if you didn't run the script sudo.\n"
  fdisk -l 2>/dev/null | cut -d: -f1 | grep "/dev/sd\w"
  detect_error
  read -p "`printf "${ALERT}"`Type the device string exactly (in the form of -> /dev/sdb): `printf "${NOCOLOR}"`" devstring
  printinfo "The device to be added is: ${USERINPUT}$devstring\n"
  cont_prompt
  clear

  # Help the user get the disk partitioned with the right type
  printinfo "Partition the disk.\n new-primary-first-default_start-default_end-type-8e-write\n The commands are: n-p-1-enter-enter-t-8e-w\n"
  fdisk $devstring
  detect_error
  pvname="$devstring""1"
  printinfo "Make sure it worked. There should now be a $pvname with type Linux LVM.\n"
  fdisk -l 2>/dev/null | cut -d: -f1 | grep "/dev/sd\w"
  detect_error
  cont_prompt
  clear

  # Now check out the current physical volumes
  pvdisplay
  detect_error
  printinfo "These are the current physical volumes\n"

  # get the vg name from input
  read -p "`printf "${ALERT}"`Type the name of the 'VG Name' exactly: `printf "${NOCOLOR}"`" vgname
  printinfo "The volume group name is: ${USERINPUT}$vgname\n"
  cont_prompt
  clear

  # add the new physical volume to the volume group
  printwarning "This script naively assumes the first partition of the new device should be added to the volume group. If this does not fit your situation hit [ctrl-c] now.\n"
  printinfo "Adding $pvname to $vgname.\n"
  vgextend $vgname $pvname
  detect_error
  cont_prompt
  clear

  vgdisplay
  detect_error
  printinfo "'Cur PV' should now be 2 (or more)\n"
  cont_prompt
  clear

  # get the name of the logical volume to extend
  lvscan
  detect_error
  read -p "`printf "${ALERT}"`Type the name of the Logical Volume exactly: `printf "${NOCOLOR}"`" lvname

  printinfo "The logical volume chosen is ${USERINPUT}$lvname\n"

  cont_prompt

  # expand the Logical volume by the amount of free space added.
  # -r expands the filesystem too, which is nice.
  # -f don't ask me any questions.
  lvextend -rf $lvname $pvname
  detect_error
  cont_prompt
  clear

  df -h
  printinfo "Has the size of / expanded as you expected? Hooray!\n"
}
#################### end of lv_extend function #######################

################## lv_reduce function ###########################
lv_reduce () {
  echo "Sorry. This has not been written yet."
}
################## end of lv_reduce function ####################

############# status function #########################
show_status () {
  (
    printf "\n${INFO}Physical Disks:${NOCOLOR}\n"
    fdisk -l 2>/dev/null
    printf "\n${INFO}Physical Volumes:${NOCOLOR}\n"
    pvdisplay
    printf "\n${INFO}Volume Groups:${NOCOLOR}\n"
    vgdisplay
    printf "\n${INFO}Logical Volumes:${NOCOLOR}\n"
    lvdisplay
    ) | less -R
}
###############################
# menu below stolen from https://gist.github.com/rmetzler/9c761f4dc1874ae6aab3
###############################

########### menu #########################
menu () {
  case $1 in
    extend)
      lv_extend
      ;;
    reduce)
      lv_reduce
      ;;
    status)
      show_status
      ;;
    help|h|*)
      echo "Logical Volume Modification automation tools."
      echo "This script must be run sudo."
      echo "Commands: "
      echo "extend    - Add a new physical disk to the Volume Group."
      echo "reduce    - Remove a physical disk from the Volume Group."
      echo "status    - Show the status of various LVM related things."
      echo "[h]elp    - Show this help."
      ;;
  esac
}
######################### end of menu #################

############ test_root ###############
test_root () {
  if [ "$(whoami)" != "root" ]
    then
      echo "This script must be run as root. sudo get me a sammich" 
      exit 2
  fi
}
############### end of test_root #################

######### Main ###############
user_command=$1
test_root
menu $user_command
