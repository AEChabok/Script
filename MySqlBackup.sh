#! /bin/bash

# Backup MySql Server
# by Amir Ezazi

# Default Username & Password Of Mysql Application
USERNAME=
PASSWORD=

# Default Directory Mysql Application Path
MYSQL="/usr/bin/mysql"
MYDUMP="/usr/bin/mysqldump"
COMPRESSOR="/usr/bin/zstd"

# Default Directory To Save Backups In, Must Be rwx By Mysql User
BACKUPTIME=30
BACKUPHOST=127.0.0.1
BACKUPPATH=
BACKUPDATE=$(date "+%Y-%m-%d")
BACKUPDIR="$BACKUPPATH/$BACKUPDATE"

# Create Backup Directory By Date Time
mkdir -p $BACKUPDIR
cd $BACKUPDIR

# Get List Of Databases In System, Remove The Table Header
DATABASES=$(echo "SHOW DATABASES" | $MYSQL -h $BACKUPHOST -u $USERNAME -p$PASSWORD | egrep -v 'Database')

# Now Loop Through Each Individual Database And Backup The Database Separately
for DATABASE in $DATABASES; do
    #Create Directory For Each Database
    DIRECTORY=$(echo $DATABASE | sed 's/.*/\u&/') 
    mkdir -p $DIRECTORY

    # Export Data From Mysql Databases To Plain Text
    $MYDUMP --opt --user=${USERNAME} --password=${PASSWORD} ${DATABASE} > ${DIRECTORY}"/"${DATABASE}".sql"

    # Compress Files
    $COMPRESSOR -z --rm ${DIRECTORY}"/"${DATABASE}".sql"
done

# Delete Backup Files Older Than ${BACKUPTIME} Days
OLDBACKUP=$(find $BACKUPPATH -type d -mtime +${BACKUPTIME})

if [ -n "$OLDBACKUP" ] ; then
    echo Deleting Old Backup Files: $OLDBACKUP
    echo $OLDBACKUP | xargs rm -rfv
fi
