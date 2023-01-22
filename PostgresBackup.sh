#! /bin/bash

# Backup MySql Server
# by Amir Ezazi

# Default Username & Password Of Postgres Application
USERNAME=
PASSWORD=

# Default Directory Postgres Application Path
PGSQL="/usr/bin/psql"
PGDUMP="/usr/bin/pg_dump"
COMPRESSOR="/usr/bin/zstd"

# Default Directory To Save Backups In, Must Be rwx By Postgres User
BACKUPTIME=30
BACKUPHOST=127.0.0.1
BACKUPPATH=
BACKUPDATE=$(date "+%Y-%m-%d")
BACKUPDIR="$BACKUPPATH/$BACKUPDATE"

# Create Backup Directory By Date Time
mkdir -p $BACKUPDIR
cd $BACKUPDIR

# Get List Of Databases In System, Remove The Table Header
DATABASES=$($PGSQL -l -t | egrep -v 'template[01]' | awk '{print $1}' | grep -v "|")

# Now Loop Through Each Individual Database And Backup The Database Separately
for DATABASE in $DATABASES; do
    #Create Directory For Each Database
    DIRECTORY=$(echo $DATABASE | sed 's/.*/\u&/') 
    mkdir -p $DIRECTORY

    # Export Data From Postgres Schema To Plain Text
    $PGDUMP -a -h $BACKUPHOST -U $USERNAME $DATABASE | gzip -9 > ${DIRECTORY}"/"${DATABASE}"-data.sql"

    # Export Data From Postgres Databases To Plain Text
    $PGDUMP -C -s  -h $BACKUPHOST -U $USERNAME $DATABASE | gzip -9 > ${DIRECTORY}"/"${DATABASE}"-schema.sql"

    # Compress Files
    $COMPRESSOR -z --rm ${DIRECTORY}"/"${DATABASE}"-data.sql"
    $COMPRESSOR -z --rm ${DIRECTORY}"/"${DATABASE}"-schema.sql"
done

# Delete Backup Files Older Than ${BACKUPTIME} Days
OLDBACKUP=$(find $BACKUPPATH -type d -mtime +${BACKUPTIME})

if [ -n "$OLDBACKUP" ] ; then
    echo Deleting Old Backup Files: $OLDBACKUP
    echo $OLDBACKUP | xargs rm -rfv
fi
