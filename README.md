# LXD Backup & Restore
A collection of backup & restore scripts for LXC and LXC

## backup.sh
- This script has been forked from [this github repo](https://github.com/triopsi/backup_all_lxc)
- todo

## restore-from-proxmox.sh
    Usage: ./restore-from-proxmox.sh -m metadata.tar.gz -b path/to/directory/with/proxmox/backups/ [-a path/to/mac-address/text/file]

	    -m  path to the compressed metadata.tar.gz file needed to import the iamge to LXD.
	    -b  path to the directory where proxmox containers' backups are located. They should be in a .tar.lzo format. One log file for each container backup is needed too to gather its name.
	    -a  path to a text file that stores each container name and the MAC address you want to manually assign. Not mandatory.
	    		Example:
	   		container1 001122334455
	    		container2 AABB3344CC33
	    		container3 22CCDDEE4433 
