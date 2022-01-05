#/bin/bash
#---------------------------------------------------------------------
# Description: Backup script for linux container with lxd
# Forked from https://github.com/triopsi/backup_all_lxc
#---------------------------------------------------------------------
errorAndQuit() {
    logmsg "Exiting now!"
    exit 1
}

logmsg() {
    echo "$(date +'%F %T') $1"
}

# the snap repository is not in the default cron $PATH, so we add it here
export PATH=$PATH:/snap/bin

#Edit the path to the backup directory
BACKUPDIR="/mnt/nas/lxd-backups"

BACKUPSTARTDATE=$(date +'%F %T')
BACKUPDATE=$(date +%F)
LXC=$(which lxc)
lxclist=$(lxc list --format csv -c n)

if [ ! -d $BACKUPDIR ];then
    logmsg "[E] Backupdir is not available"
    errorAndQuit
fi
logmsg "[-] Starting backup at $BACKUPSTARTDATE"
for container in $lxclist
do
    logmsg "Begining backup for $container"

    if $LXC info $container > /dev/null 2>&1; then
        logmsg "[✓] Container $container found, continuing.."
    else
        logmsg "[E] Container $container NOT found, exiting lxdbackup"
        continue
    fi

    #Create Snapshot
    logmsg "[-] Creating snapshot"
    if $LXC snapshot $container $BACKUPDATE; then
        logmsg "[✓] Succesfully created snaphot $BACKUPDATE on container $container"
    else
        logmsg "[E] Could not create snaphot $BACKUPDATE on container $container"
        errorAndQuit
    fi

    #Publish snapshot
    logmsg "[-] Publishing snapshot"
    if $LXC publish --force --quiet $container/$BACKUPDATE --alias $container-backup-$BACKUPDATE; then
        logmsg "[✓] Succesfully published an image of $container-backup-$BACKUPDATE"
    else
        logmsg "[E] Could not publish image from $container-backup-$BACKUPDATE"
        errorAndQuit
    fi

    #exists backup dir with date as directoryname
    if [ ! -d $BACKUPDIR/$BACKUPDATE ];then
        mkdir $BACKUPDIR/$BACKUPDATE
	logmsg "[✓] Backup directory created"
    fi
    #Export container as tar
    logmsg "[-] Exporting image"
    if $LXC image export --quiet $container-backup-$BACKUPDATE $BACKUPDIR/$BACKUPDATE/$container; then
        logmsg "[✓] Succesfully export $container-backup-$BACKUPDATE to $BACKUPDIR/$BACKUPDATE/$container"
    else
        logmsg "[E] Could not export $container-backup-$BACKUPDATE from container $container"
        errorAndQuit
    fi

    #delete image
    logmsg "[-] Cleaning image"
    if $LXC image delete $container-backup-$BACKUPDATE; then
        logmsg "[✓] Succesfully delete temp image for $container"
    fi

    #delete snapshot
    logmsg "[-] Cleaning snapshot"
    if $LXC delete $container/$BACKUPDATE; then
        logmsg "[✓] Succesfully delete temp snapshot for $container"
    fi

    #save the config file
    logmsg "[-] Backup config file"
    if [ -e /var/lib/lxd/containers/$container/backup.yaml ];then
        cp /var/lib/lxd/containers/$container/backup.yaml $BACKUPDIR/$BACKUPDATE/$container.yaml
        logmsg "[✓] Succesfully copied LXC config file"
    fi
    logmsg "Ending backup for $container"
done

logmsg "exporting LXD configuration"
lxd init --dump > $BACKUPDIR/$BACKUPDATE/lxd.config

BACKUPENDDATE=$(date +'%F %T')
logmsg "[✓] Backup is done at $BACKUPENDDATE" 
