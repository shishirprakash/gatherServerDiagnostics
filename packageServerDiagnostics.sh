#!/bin/bash

outDir=$1
if [ "n$outDir" = "n" ]; then
  outDir=`pwd`
fi
if [ ! -d $outDir ]; then
  echo ERROR: Could not access output directory $outDir
  exit 1
fi

logDir=/opt/mapr/logs
fileName=$outDir/diagnostics.server.$HOSTNAME.`date +"%Y-%m-%d_%H_%M_%S"`.tgz

tarMsgs="`tar --ignore-failed-read -czf $fileName $logDir/netstat.pan.$HOSTNAME.out $logDir/cldb.threads.$HOSTNAME.out $logDir/cldb.pid.$HOSTNAME.out $logDir/gatherServerDiagnostics.$HOSTNAME.out $logDir/guts.$HOSTNAME.out $logDir/iostat.$HOSTNAME.out $logDir/mfs.threads.$HOSTNAME.out $logDir/mpstat.$HOSTNAME.out $logDir/mrconfig.dbinfo.threads.$HOSTNAME.out $logDir/mrconfig.info.threads.$HOSTNAME.out $logDir/top.processes.$HOSTNAME.out $logDir/top.threads.$HOSTNAME.out $logDir/vmstat.$HOSTNAME.out /opt/mapr/hadoop/hadoop-0.20.2/logs/*tasktracker*log* /opt/mapr/hadoop/hadoop-2*/logs/*nodemanager*log* /opt/mapr/logs/cldb* /opt/mapr/logs/mfs* 2>&1`" 

ret=$?
if [ $ret -eq 0 ]; then
  echo Diagnostic file created at $fileName 
else
  if [ $ret != 1 ] || [ `echo "$tarMsgs" | grep -v -e "Cannot stat: No such file or directory" -e "file changed as we read it" -e "Removing leading" | wc -l` -ne 0 ]; then
    echo ERROR: Failed to create diagnostic file $fileName with exit code $ret
    echo tar --ignore-failed-read -czf $fileName $logDir/netstat.pan.$HOSTNAME.out $logDir/cldb.threads.$HOSTNAME.out $logDir/cldb.pid.$HOSTNAME.out $logDir/gatherServerDiagnostics.$HOSTNAME.out $logDir/guts.$HOSTNAME.out $logDir/iostat.$HOSTNAME.out $logDir/mfs.threads.$HOSTNAME.out $logDir/mpstat.$HOSTNAME.out $logDir/mrconfig.dbinfo.threads.$HOSTNAME.out $logDir/mrconfig.info.threads.$HOSTNAME.out $logDir/top.processes.$HOSTNAME.out $logDir/top.threads.$HOSTNAME.out $logDir/vmstat.$HOSTNAME.out /opt/mapr/hadoop/hadoop-0.20.2/logs/*tasktracker*log* /opt/mapr/hadoop/hadoop-2*/logs/*nodemanager*log* /opt/mapr/logs/cldb* /opt/mapr/logs/mfs*
    echo "$tarMsgs"
  else
    echo Diagnostic file created at $fileName
  fi
fi

