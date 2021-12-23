#/bin/bash
#---------------------------------------------------------------------
# Description: Backup script for linux container with lxd
# Forked from https://github.com/triopsi/backup_all_lxc
#---------------------------------------------------------------------
APWD=$(pwd);

function errorAndQuit {
    echo "Exit now!"
    exit 1
}

function wait_bar () {
  for i in {1..10}
  do
    printf '= %.0s' {1..$i}
    sleep $1s
  done
}

#Edit the path to the backup directory
BACKUPDIR="/backup/data"


# ------------------------------------------------------------------------------------------
# Logging
#-------------------------------------------------------------------------------------------
#Those lines are for logging purposes
echo "Welcome to the backup script for lxc"
echo "========================================="
echo "Backup started..."
echo "========================================="


BACKUPSTARTDATE=$(date +"%y-%m-%d-%H-%M")
BACKUPDATE=$(date +"%y-%m-%d")
LXC=$(which lxc)
lxclist=$(lxc list --format csv -c n)

if [ ! -d $BACKUPDIR ];then
    mkdir -p $BACKUPDIR
    echo "[✓] Backupdir is created"
fi
echo "[✓] Start backup at $BACKUPSTARTDATE"
for container in $lxclist
do
    echo "------------------------- Begin backup for $container -------------------------"

    if $LXC info $container > /dev/null 2>&1; then
        echo "[✓] Container $container found, continuing.."
    else
        echo "[E] Container $container NOT found, exiting lxdbackup"
        continue
    fi

    #Create Snapshot
    echo "[✓] Create snapshot"
    if $LXC snapshot $container $BACKUPDATE; then
        echo "[✓] Succesfully created snaphot $BACKUPDATE on container $container"
    else
        echo "[E] Could not create snaphot $BACKUPDATE on container $container"
        errorAndQuit
    fi

    #Publish snapshot
    echo "[✓] Snapshot pubplish"
    if $LXC publish --force $container/$BACKUPDATE --alias $container-backup-$BACKUPDATE; then
        echo "[✓] Succesfully published an image of $container-backup-$BACKUPDATE"
    else
        echo "[E] Could not publish create image from $container-backup-$BACKUPDATE"
        errorAndQuit
    fi

    #exists backup dir with date as directoryname
    echo "[✓] Create backup directory"
    if [ ! -d $BACKUPDIR/$BACKUPDATE ];then
        mkdir $BACKUPDIR/$BACKUPDATE
    fi
    #Export container as tar
    echo "[✓] Create image, export as tar"
    if $LXC image export $container-backup-$BACKUPDATE $BACKUPDIR/$BACKUPDATE/$container; then
        echo "[✓] Succesfully export $container-backup-$BACKUPDATE to $BACKUPDIR/$BACKUPDATE/$container"
        ls -all $BACKUPDIR/$BACKUPDATE
    else
        echo "[E] Could not export $container-backup-$BACKUPDATE from container $container"
        errorAndQuit
    fi

    #delete image
    echo "[✓] Clean image"
    if $LXC image delete $container-backup-$BACKUPDATE; then
        echo "[✓] Succesfully delete temp image for $container"
    fi

    #delete snapshot
    echo "[✓] Clean snapshot"
    if $LXC delete $container/$BACKUPDATE; then
        echo "[✓] Succesfully delete temp snapshot for $container"
    fi

    #save the config file
    echo "[✓] Backup config file"
    if [ -e /var/lib/lxd/containers/$container/backup.yaml ];then
        cp /var/lib/lxd/containers/$container/backup.yaml $BACKUPDIR/$BACKUPDATE/$container.yaml
        echo "[✓] Backup config file success"
    fi
    echo "------------------------- backup $container end -------------------------"
done

echo "exporting LXD configuration"
lxd init --dump > $BACKUPDIR/$BACKUPDATE/lxd.config

BACKUPENDDATE=$(date +"%y-%m-%d-%H-%M")
echo "[✓] Backup is done at $BACKUPENDDATE" 
