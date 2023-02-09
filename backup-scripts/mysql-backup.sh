#!/bin/bash
# Maintainer: 
# Backup all database, each db to one file
DATE=`date +%m%d`
YESTERDAY=`date -d "yesterday" +%m%d`
TIME=`date +%m%d%H%M`
HOST=`hostname -f`
ROLE=`echo $HOST | cut -d. -f2`
DBNAMES=`mysql --defaults-file=/etc/mysql/debian.cnf -e "show databases" | grep -v 'information_schema\|performance_schema\|Database'`
CMD="mysqldump --defaults-file=/etc/mysql/debian.cnf --routines --ignore-table=mysql.event"
OUTDIR="/var/backups/${HOST}_db_${DATE}"
YESTERDAY_DIR="/var/backups/${HOST}_db_${YESTERDAY}"

# make backup dir
test -d $OUTDIR || mkdir -p $OUTDIR


# dump and gzip database one by one
for DB in $DBNAMES; do
	eval $CMD $DB > $OUTDIR/$DB.$TIME.sql

	if [ $? -ne 0 ]
	then
		echo "`date`: ERROR: dump $DBNAMES: eval $CMD $DB > $OUTDIR/$DB.$TIME.sql " >> /var/log/backup_mysql.log
		continue
	fi

	gzip $OUTDIR/$DB.$TIME.sql
# Check file size
	newfile_size=`ls -l $OUTDIR/$DB.$TIME.sql.gz | cut -f5 -d " "`
	oldfile_size=$(ls -l $YESTERDAY_DIR/$DB.*.sql.gz 2>>/var/log/backup_mysql.log | cut -f5 -d " " | tail -1)
	filesize_humanreadable=`ls -lh $OUTDIR/$DB.$TIME.sql.gz | cut -f5 -d " "`

	[[ -z $oldfile_size ]] && oldfile_size=$newfile_size

	sizediff1=`calc $newfile_size/$oldfile_size*100`
	sizediff=`echo $sizediff1 | cut -f1 -d\. `
	[[ $sizediff -lt 125 ]] && [[ $sizediff -gt 80 ]] && ( echo `date`: INFO: created backup file $filesize_humanreadable $OUTDIR/$DB.$TIME.sql.gz >> /var/log/backup_mysql.log ) || (echo `date`: INFO: new backup file $filesize_humanreadable $OUTDIR/$DB.$TIME.sql.gz is so different than it on yesterday $sizediff \% >> /var/log/backup_mysql.log )

#	if [ $newfile_size -lt $(($oldfile_size - 50)) ]
#	then
#		echo `date`: WARNING: new backup file $filesize_humanreadable $OUTDIR/$DB.$TIME.sql.gz is smaller than it on yesterday \( $newfile_size \< $oldfile_size \) >> /var/log/backup_mysql.log
#    else
#		echo `date`: INFO: created backup file $filesize_humanreadable $OUTDIR/$DB.$TIME.sql.gz >> /var/log/backup_mysql.log
#	fi

done


rsync -r $OUTDIR 10.130.45.40::mysql/$HOST/ 2> /tmp/backupsql 
if [ $? -eq 0 ]
then
		filesize_humanreadable=`ls -lh $OUTDIR/$DB.$TIME.sql.gz | cut -d" " -f5`
		echo "`date`: INFO: already backup $filesize_humanreadable $OUTDIR/$DB.$TIME.sql.gz " >> /var/log/backup_mysql.log
else
		echo -n "`date`: ERROR: rsync: " >> /var/log/backup_mysql.log 
		cat /tmp/backupsql >> /var/log/backup_mysql.log
		cat > /tmp/backupsql
fi


#Remove 4 days old files
OLD_STAMP=`date -d "4 days ago" +%m%d`
OLDDIR="/var/backups/${HOST}_db_${OLD_STAMP}"
if [ -d $OLDDIR ]; then
	foldersize_humanreadable=`du -sh $OLDDIR | cut -f1`
	rm -r $OLDDIR && echo `date`: INFO: deleted old backup folder: $foldersize_humanreadable $OLDDIR >> /var/log/backup_mysql.log || echo `date`: ERROR: cannot delete old backup $OLDDIR >> /var/log/backup_mysql.log
#        rm -rf $OLDDIR 2>&1 | tee -a /var/log/backup_mysql.log && date >> /var/log/backup_mysql.log
fi
