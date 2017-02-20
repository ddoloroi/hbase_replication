# hbase_replication
Replicate HBase tables between Cloudera Hadoop clusters

##Introduction
This script lets you replicate HBase tables from one Hadoop cluster to another. The highlights are:
 - Support for Kerberised cluster environment
 - Support for Namenode HA
 - Uses Distcp to efficiently copy the table snapshot to destination cluster
 - Email alerts

##Pre-requisites
 - Cloudera Hadoop cluster with an edge node running on any Hadoop compatible Linux Operating system
 - Install the following packages in your edge nodes(or wherever the script is running):
   * mailx
 - If using a Kerberised hadoop cluster, generate keytab file for HBase and HDFS user and store it in a secure location.
   Reference: https://kb.iu.edu/d/aumh
      
##List of Scripts
 - hbase_repl_source.sh
 - hbase_repl_destination.sh
 - findactivenamenode
 - findactivenamenode.py  //Credit for this script goes to original author at http://stackoverflow.com/questions/26648214/any-command-to-get-active-namenode-for-nameservice-in-hadoop

##Usage
 - Open all script files(except the python script) and edit values under the section 'User configurable variables'
 - Create a logfile as per the variables you set in step #1
 - Copy the script 'hbase_repl_source.sh' to source cluster. It should be in the 'BaseDir' variable you set in step #1
 - Copy the script 'findactivenamenode' to '/bin' directiory in destination cluster. Set execute permission.
 - Copy the remaining scripts to destination cluster. It should be in the 'BaseDir' variable you set in step #1
```sh
./hbase_repl_source.sh TableList.txt
```

##Automation
Once manual testing of script is successful, you can automate HBase replication jobs via cronjobs:
```sh 
00 10 * * * bash /var/lib/hbase/scripts/replication/hbase_replicate_sandbox.sh /var/lib/hbase/scripts/replication/Tablelist.txt
```
