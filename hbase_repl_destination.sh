#!/bin/bash
# Author: Pratap Raj
# Purpose: Restore Hbase snapshot in destination cluster. This script is part of the HBase replication tool.
# Install in source cluster

############     User configuratble variables - Edit as per your environment    #############
#############################################################################################
# BaseDir is the directory in DESTINATION CLUSTER where this script is to be copied into. 
#Usually its inside a subfolder in the hbase home directory - /var/lib/hbase
BaseDir='/var/lib/hbase/scripts/replication'

# HbaseKeytab is path to keytab file for 'hbase' user. This is relevant only in Kerberised cluster
HbaseKeytab='/var/lib/hbase/hbase.keytab'

# LogFile is the file path for log file. Ensure that you set its ownership to the 'hbase' user
LogFile='/var/log/hbasereplication.log'

# MailAddress is the email address to which alerts are to be sent
MailAddress=''
############### User configurable variables end. DO NOT edit anything below ###############

pushd $BaseDir
kdestroy
kinit -kt $HbaseKeytab hbase >> $LogFile

HbaseTable="$1"
HBaseSnapshot="$2"

#Function to send email alert
function mailalert {
if [ "$1" == "success" ]; then
 SubjectLine="HBase restore report: Successful"
 MessageBody1="HBase restore at destination cluster is successful"
 MessageBody2=""
else
 SubjectLine="HBase restore report: Failed"
 MessageBody1="HBase restore at destination cluster failed. Check log snippet below for details:"
 MessageBody2=$(tail -1 $LogFile)
 echo -e "$MessageBody1\n\n$MessageBody2" | mailx -s "$SubjectLine" "$MailAddress"
fi
}

#validate arguments
if [ "$#" != 2 ]; then
 echo "$(date +%D\ %R) ERROR: Incorrect number of arguments. Script will exit now" >> $LogFile
 mailalert failed
 exit 1;
fi

#Disable and drop table before restore
echo "disable '$HbaseTable'"|hbase shell -n >> /dev/null
echo "drop '$HbaseTable'"|hbase shell -n >> /dev/null
if [ "$?" != "0" ]; then
 echo "$(date +%D\ %R) WARN: Unable to drop table $HbaseTable" >> $LogFile
fi

#Restore table
echo "restore_snapshot '$HBaseSnapshot'"|hbase shell -n 2>> $LogFile
if [ "$?" != "0" ]; then
 echo "$(date +%D\ %R) ERROR: Unable to restore snapshot $HBaseSnapshot to $HbaseTable" >> $LogFile
 mailalert failed
else
 echo "$(date +%D\ %R) INFO: Table $HbaseTable has been successfully restored from snapshot $HBaseSnapshot"  >> $LogFile
 mailalert success
 echo "$(date +%D\ %R) INFO: Removing snapshot $HBaseSnapshot" >> $LogFile
 echo "delete_snapshot '$HBaseSnapshot'"|hbase shell -n >> /dev/null
fi