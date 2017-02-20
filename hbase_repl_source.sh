#!/bin/bash
# Author: Pratap Raj
# Purpose: Replicate HBase tables to another cluster
# Install in source cluster

############     User configuratble variables - Edit as per your environment    #############
#############################################################################################

# BaseDir is the directory in SOURCE CLUSTER where this script is to be copied in to.
#Usually its inside a subfolder in the hbase home directory - /var/lib/hbase
BaseDir='/var/lib/hbase/scripts/replication'

# HbaseTableList is an argument to be passed while calling this script. It should be a file that contains the namespace:tablename list, seperated by newlines. 
#For adding table test in default namespace,  use default:test
HbaseTableList=$1

# DestinationClusterHost should be edge node hostname of destination cluster
DestinationClusterHost=''

# DestinationClusterUser should be a user with admin privileges on HBase. Usually this is 'hbase'
DestinationClusterUser='hbase'

# HbaseKeytab is path to keytab file for 'hbase' user. This is relevant only in Kerberised cluster
HbaseKeytab='/var/lib/hbase/hbase.keytab'

# LogFile is the file path for log file. Ensure that you set its ownership to the 'hbase' user
LogFile='/var/log/hbasereplication.log'

# MailAddress is the email address to which alerts are to be sent
MailAddress=''
############### User configurable variables end. DO NOT edit anything below ################

#Validate argument
if [ ! -s "$1" ]; then
 echo "Invalid script usage!"
 echo "Usage example: $0 TableList.txt"
 exit 1;
fi

pushd $BaseDir

# Find out active namenode in destination cluster
ActiveNamenode=$(ssh -l $DestinationClusterUser $DestinationClusterHost "findactivenamenode")
pushd $BaseDir

#Function to send email alert
function mailalert {
if [ "$1" == "success" ]; then
 SubjectLine="HBase replication report: Successful"
 MessageBody1="HBase replication is successful"
 MessageBody2=""
else
 SubjectLine="HBase replication report: Failed"
 MessageBody1="HBase replication has failed. Check log snippet below for details:"
 MessageBody2=$(tail -1 $LogFile)
fi
echo -e "$MessageBody1\n\n$MessageBody2" | mailx -s "$SubjectLine" "$MailAddress"
}

#Check if HbaseTableList file exists
if [ ! -s "$HbaseTableList" ]; then
 echo "$(date +%D\ %R) ERROR: $HbaseTableList not present in correct format. Script will exit now.." >> $LogFile
 mailalert failed
 exit 1;
fi

# Acquire keytab for HBase user in source cluster
kdestroy
kinit -V -kt "$HbaseKeytab" hbase >> $LogFile

# Create local snapshots
for i in `cat $HbaseTableList`
 do
        NameSpace=$(echo $i|cut -d: -f1)
        TableName=$(echo $i|cut -d: -f2)
        echo "snapshot '$NameSpace:$TableName', '${TableName}_repl_$(date +%F)'"| hbase shell -n 2>> $LogFile

        if echo "list_snapshots"|hbase shell -n|grep "${TableName}_repl_$(date +%F)"; then
                echo "$(date +%D\ %R) INFO: Successfully created snapshot" >> $LogFile
        fi

        hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot -snapshot "${TableName}_repl_$(date +%F)" -overwrite -copy-to hdfs://$ActiveNamenode:8020/hbase -mappers 3
        if [ "$?" != "0" ]; then
                echo "$(date +%D\ %R) ERROR: Snapshot copy failed" >> $LogFile
                mailalert failed
        else
                echo "$(date +%D\ %R) INFO: Snapshot copy successful" >> $LogFile
                echo "$(date +%D\ %R) INFO: Removing snapshot ${TableName}_repl_$(date +%F)" >> $LogFile
                echo "delete_snapshot '${TableName}_repl_$(date +%F)'"|hbase shell -n >> /dev/null
        fi

        echo "$(date +%D\ %R) INFO: Restoring snapshot for $NameSpace:$TableName in $DestinationClusterHost" >> $LogFile
        ssh -l $DestinationClusterUser $DestinationClusterHost "bash $BaseDir/hbase_repl_destination.sh '$NameSpace:$TableName' '${TableName}_repl_$(date +%F)'" 2>> $LogFile
 done