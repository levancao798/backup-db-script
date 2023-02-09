#!/bin/bash

/usr/bin/find /mnt/esbackup/mongo_g3/ -type f -mtime +4 -exec rm -f {} \;
/usr/bin/find /mnt/esbackup/mongo_g3_db02/ -type f -mtime +4 -exec rm -f {} \;
