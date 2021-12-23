#! /bin/bash

set -e

metadata_file=''
backup_dir=''
macaddress_file=''

print_usage() {
  echo
  echo "Usage: $0 -m metadata.tar.gz -b path/to/directory/with/proxmox/backups/ [-a path/to/mac-address/text/file]"
  echo
  echo "	-m  path to the compressed metadata.tar.gz file needed to import the iamge to LXD."
  echo "	-b  path to the directory where proxmox containers' backups are located. They should be in a .tar.lzo format. One log file for each container backup is needed too to gather its name."
  echo "	-a  path to a text file that stores each container name and the MAC address you want to manually assign. Not mandatory."
  echo "	    	Example:"
  echo "	   	container1 001122334455" 
  echo "	    	container2 AABB3344CC33"
  echo "	    	container3 22CCDDEE4433"
  echo
}

while getopts 'm:b:a:h' flag; do
  case "${flag}" in
    m) metadata_file="${OPTARG}";;
    b) backup_dir="${OPTARG}" ;;
    a) macaddress_file="${OPTARG}" ;;
    h) print_usage
       exit 1 ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [[ $metadata_file == '' || $backup_dir == '' ]]; then
  print_usage
  exit 1
fi

for image in $(ls $backup_dir*.tar.lzo)
do
  echo "Working on $image"

  logfile=${image%????????}.log
  label=$(grep "CT Name" $logfile | cut -d ' ' -f6)
  echo " -> CT name is $label"

  echo " -> unarchiving lzo to tar"
  lzop -d $image

  imagetar=${image%????}
  echo " -> tar file is $imagetar"

  echo " -> importing $imagetar to lxd"
  fingerprint=$(lxc image import $metadata_file $imagetar | awk 'NF>1{print $NF}')

  echo " -> lxc fingerprint is $fingerprint"

  echo " -> launching CT $label"
  lxc launch $fingerprint $label

  if [[ $macaddress_file != ''  ]]; then
    echo " -> getting MAC address from file $macaddress_file"
    macaddress=$(grep $label $macaddress_file | cut -d ' ' -f2)
    echo " -> MAC address is $macaddress"
  
    echo " -> stopping CT $label"
    lxc stop $label
  
    echo " -> setting MAC address to config file"
    lxc config set $label volatile.eth0.hwaddr $macaddress

    echo " -> starting CT $label"
    lxc start $label
  fi
done
