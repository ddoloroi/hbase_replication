#!/bin/bash
# Author: Pratap Raj
# Purpose: This is a dependancy for HBase replication script, in order to find the active namenode in destination cluster
############     User configuratble variables - Edit as per your environment    #############
#############################################################################################

# ReplicationScriptsDir is the directory in DESTINATION CLUSTER where the replication scripts are available. 
#Usually its inside a subfolder in the hbase home directory - /var/lib/hbase
ReplicationScriptsDir='/var/lib/hbase/scripts/replication'

# HdfsKeytab is path to keytab file for 'hdfs' user. This is relevant only in Kerberised cluster
HdfsKeytab='/var/lib/hbase/hdfs.keytab'
############### User configurable variables end. DO NOT edit anything below #################

pushd $ReplicationScriptsDir >> /dev/null
kdestroy >> /dev/null
kinit -kt $HdfsKeytab hdfs >> /dev/null
ActivenamenodeIdlist=$(python findactivenamenode.py)
ActivenamenodeId=$(echo $ActivenamenodeIdlist|awk '{print $1}')
ActivenamenodeHost=$(grep -A1 "dfs.namenode.rpc-address.nameservice1.$ActivenamenodeId" /etc/hadoop/conf/hdfs-site.xml|grep 8020|cut -d'>' -f2|cut -d: -f1)
echo "$ActivenamenodeHost"
kdestroy >> /dev/null