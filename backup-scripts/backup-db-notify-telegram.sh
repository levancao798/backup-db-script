#!/bin/bash 
################################################################
##
##   MySQL Database Backup Script
##   Last Update: Jul 09, 2020
##
################################################################
 
export PATH=/bin:/usr/bin:/usr/local/bin
TODAY=`date +'%m-%d-%Y'`
 
################################################################
################## Update below values  ########################
 
DB_BACKUP_PATH='/root/tuyendd/db_backup'
DATABASE_NAME=`mysql --defaults-file=/etc/mysql/debian.cnf -e "show databases" | grep -v 'information_schema\|performance_schema\|Database\|mysql\|sys'`
CMD="mysqldump --defaults-file=/etc/mysql/debian.cnf --routines --ignore-table=mysql.event"
BACKUP_RETAIN_DAYS=14   ## Number of days to keep local backup copy
LOGFILE='/root/mysql-backup-output.log'
#CREDENTIALS_FILE='/home/tuyendd/scripts/extra.my.cnf'
USERID="-331965421"
TOKEN="1157459635:AAHoKBShKDnF1UQop23JK4oKapglsjt1mYY"
TIMEOUT="10"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"
DATE_EXEC="$(date "+%d %b %Y %H:%M")"
TMPFILE='/tmp/ipinfo-$DATE_EXEC.txt'
HOSTNAME=$(hostname)

#################################################################
 
mkdir -p ${DB_BACKUP_PATH}/${TODAY}
echo "${TODAY} Backup started for database - ${DATABASE_NAME}" >> $LOGFILE 2>&1
 
 for DB in $DATABASE_NAME; do
   $CMD $DB > ${DB_BACKUP_PATH}/${TODAY}/${DB}-${TODAY}.sql

gzip ${DB_BACKUP_PATH}/${TODAY}/${DB}-${TODAY}.sql
done

if [ $? -eq 0 ]; then
  TEXT=$(echo "${DATE_EXEC} Database $DATABASE_NAME backup successfully completed from $HOSTNAME") && curl -s -X POST --max-time $TIMEOUT $URL -d "chat_id=$USERID" -d text="$TEXT" > /dev/null
else
  TEXT1=$(echo "${DATE_EXEC} Error found during backup") && curl -s -X POST --max-time $TIMEOUT $URL -d "chat_id=$USERID" -d text="$TEXT1" > /dev/null
  exit 1
fi
 
##### Remove backups older than {BACKUP_RETAIN_DAYS} days  #####
 
DBDELDATE=`date +'%m-%d-%Y' --date="${BACKUP_RETAIN_DAYS} days ago"`
 
if [ ! -z ${DB_BACKUP_PATH} ]; then
      cd ${DB_BACKUP_PATH}
      if [ ! -z ${DBDELDATE} ] && [ -d ${DBDELDATE} ]; then
            rm -rf ${DBDELDATE}
      fi
fi
### End of script ####
