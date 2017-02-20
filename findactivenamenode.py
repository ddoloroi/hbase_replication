#!/usr/bin/env python
# coding: UTF-8
# Credit goes to original author : http://stackoverflow.com/questions/26648214/any-command-to-get-active-namenode-for-nameservice-in-hadoop

import xml.etree.ElementTree as ET
import subprocess as SP
if __name__ == "__main__":
    hdfsSiteConfigFile = "/etc/hadoop/conf/hdfs-site.xml"

    tree = ET.parse(hdfsSiteConfigFile)
    root = tree.getroot()
    hasHadoopHAElement = False
    activeNameNode = None
    for property in root:
        if "dfs.ha.namenodes" in property.find("name").text:
            hasHadoopHAElement = True
            nameserviceId = property.find("name").text[len("dfs.ha.namenodes")+1:]
            nameNodes = property.find("value").text.split(",")
            for node in nameNodes:
                #get the namenode machine address then check if it is active node
                for n in root:
                    prefix = "dfs.namenode.rpc-address." + nameserviceId + "."
                    elementText = n.find("name").text
                    if prefix in elementText:
                        nodeAddress = n.find("value").text.split(":")[0]

                        args = ["hdfs haadmin -getServiceState " + node]
                        p = SP.Popen(args, shell=True, stdout=SP.PIPE, stderr=SP.PIPE)

                        for line in p.stdout.readlines():
                            if "active" in line.lower():
                                print node
                                break;
                        for err in p.stderr.readlines():
                            print "Error executing Hadoop HA command: ",err
            break
    if not hasHadoopHAElement:
        print "Hadoop High-Availability configuration not found!"