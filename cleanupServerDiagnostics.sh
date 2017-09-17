#!/bin/bash

logDir=/opt/mapr/logs

rm -rf $logDir/netstat.pan.$HOSTNAME.out $logDir/cldb.threads.$HOSTNAME.out $logDir/cldb.pid.$HOSTNAME.out $logDir/gatherServerDiagnostics.$HOSTNAME.out $logDir/guts.$HOSTNAME.out $logDir/iostat.$HOSTNAME.out $logDir/mfs.threads.$HOSTNAME.out $logDir/mpstat.$HOSTNAME.out $logDir/mrconfig.dbinfo.threads.$HOSTNAME.out $logDir/mrconfig.info.threads.$HOSTNAME.out $logDir/top.processes.$HOSTNAME.out $logDir/top.threads.$HOSTNAME.out $logDir/vmstat.$HOSTNAME.out 

echo Cleaned up diagnostics from $logDir
