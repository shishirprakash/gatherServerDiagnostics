#!/bin/bash

logDir=/opt/mapr/logs
lightPollingInterval=5
heavyPollingInterval=20

gatherAllThreads=0
gatherCldbThreadsCpu=1
gatherAllProcesses=1
gatherHWResources=1

gatherMfsThreadsCpu=1
gatherMrconfigThreads=1
gatherGuts=1
gatherCldbStacks=1
gatherCldbPid=0

gatherNetstatPan=0

if [ `ps -ef | grep -w "gatherServerDiagnostics.sh daemon" | grep -v -w -e grep | tr -s '  ' ' ' | cut -f 2-3 -d " " | grep -v -w -e $$ | wc -l` -ne 0 ]; then
  echo ERROR: This script is already running!
  ps -ef | grep -w "gatherServerDiagnostics.sh daemon" | grep -v -w -e grep
  exit 1
fi

if [ "n$1" = "ndaemon" ]; then

  topRunning=0
  gutsRunning=0
  topPid=-1
  gutsPid=-1
  mfsPid=-1
  iostatPid=-1
  mpstatPid=-1
  vmstatPid=-1
  topThreadsPid=-1
  topProcessesPid=-1
  nextLightPolling=0
  nextHeavyPolling=0
  
while true; do
  now=`date +%s`
  if [ $now -ge $nextLightPolling ]; then
    nextLightPolling=$(( $now + $lightPollingInterval ))
    if [ $gatherCldbStacks -eq 1 ] && [ "n`cat /opt/mapr/pid/cldb.pid`" != "n" ] && [ -d /proc/`cat /opt/mapr/pid/cldb.pid` ]; then
      kill -3 `cat /opt/mapr/pid/cldb.pid`
    fi
    if [ $gatherMrconfigThreads -eq 1 ]; then
      date=`date +"%Y-%m-%d %H:%M:%S.%N" | cut -b 1-23`
      echo $date >> $logDir/mrconfig.dbinfo.threads.$HOSTNAME.out
      /opt/mapr/server/mrconfig dbinfo threads >> $logDir/mrconfig.dbinfo.threads.$HOSTNAME.out 2>&1
      echo $date >> $logDir/mrconfig.info.threads.$HOSTNAME.out
      /opt/mapr/server/mrconfig info threads >> $logDir/mrconfig.info.threads.$HOSTNAME.out 2>&1
    fi
  fi
  if [ $now -ge $nextHeavyPolling ]; then
    nextHeavyPolling=$(( $now + $heavyPollingInterval ))
    if [ $gatherNetstatPan -eq 1 ]; then
      netstat -pan | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/netstat.pan.$HOSTNAME.out 2>&1 &
    fi
    if [ $gatherCldbPid -eq 1 ]; then
      echo `date +"%Y-%m-%d %H:%M:%S"` `cat /opt/mapr/pid/cldb.pid` >> $logDir/cldb.pid.$HOSTNAME.out 2>&1
    fi
    if [ $gatherHWResources -eq 1 ]; then
      if [ ! -d /proc/$iostatPid ]; then
        iostat -cdmx $lightPollingInterval  | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/iostat.$HOSTNAME.out 2>&1 &
        ret=$?
        iostatPid=$!
        if [ $ret -ne 0 ]; then
          iostatPid=-1
        fi
      fi
      if [ ! -d /proc/$mpstatPid ]; then
        mpstat -P ALL $lightPollingInterval | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/mpstat.$HOSTNAME.out 2>&1 &
        ret=$?
        mpstatPid=$!
        if [ $ret -ne 0 ]; then
          mpstatPid=-1
        fi
      fi
      if [ ! -d /proc/$vmstatPid ]; then
        vmstat -n -SM $lightPollingInterval | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/vmstat.$HOSTNAME.out 2>&1 &
        ret=$?
        vmstatPid=$!
        if [ $ret -ne 0 ]; then
          vmstatPid=-1
        fi
      fi
    fi
    if [ $gatherAllThreads -eq 1 ]; then
      if [ ! -d /proc/$topThreadsPid ]; then
        top -b -H -d $heavyPollingInterval | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/top.threads.$HOSTNAME.out 2>&1 &
        ret=$?
        topThreadsPid=$!
        if [ $ret -ne 0 ]; then
          topThreadsPid=-1
        fi
      fi
    fi
    if [ $gatherAllProcesses -eq 1 ]; then
      if [ ! -d /proc/$topProcessesPid ]; then
        top -b -d $heavyPollingInterval | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' | grep -v -e " 0\.0 *0\.0 " >> $logDir/top.processes.$HOSTNAME.out 2>&1 &
        ret=$?
        topProcessesPid=$!
        if [ $ret -ne 0 ]; then
          topProcessesPid=-1
        fi
      fi
    fi
    if [ $gatherCldbThreadsCpu -eq 1 ]; then
      newCldbPid=`cat /opt/mapr/pid/cldb.pid 2> /dev/null`
      if [ $cldbTopRunning -eq 1 ] && [ ! -d /proc/$cldbTopPid ]; then
        cldbTopRunning=0
      fi
      if [ "n$newCldbPid" != "n" ] && [ "n$newCldbPid" != "n$cldbPid" ]; then
        cldbPid=$newCldbPid
        if [ $cldbTopRunning -eq 1 ]; then
          kill -9 $cldbTopPid
        fi
        echo start top 1 top -b -H -d $lightPollingInterval $newCldbPid
        top -b -H -d $lightPollingInterval -p $newCldbPid | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' | grep -v -e " S *0\.0 " | grep -w java >> $logDir/cldb.threads.$HOSTNAME.out 2>&1 &
        ret=$?
        cldbTopPid=$!
        if [ $ret -eq 0 ]; then
          cldbTopRunning=1
        else
          cldbTopRunning=0;
          cldbTopPid=-1
        fi
        echo start top 1 ret $ret
      elif [ "n$newCldbPid" != "n" ] && [ "n$newCldbPid" = "n$cldbPid" ] && [ $cldbTopRunning -eq 0 ]; then
        echo start top 2 top -b -H -d $lightPollingInterval $newCldbPid
        top -b -H -d $lightPollingInterval -p $newCldbPid | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' | grep -v -e " S *0\.0 " | grep -w java >> $logDir/cldb.threads.$HOSTNAME.out 2>&1 &
        ret=$?
        cldbTopPid=$!
        if [ $ret -eq 0 ]; then
          cldbTopRunning=1
        else
          cldbTopRunning=0;
          cldbTopPid=-1
        fi
        echo start top 2 ret $ret
      fi
    fi
    if [ $gatherGuts -eq 1 ] || [ $gatherMfsThreadsCpu -eq 1 ]; then
      newMfsPid=`/sbin/pidof mfs`
      if [ $topRunning -eq 1 ] && [ ! -d /proc/$topPid ]; then
        topRunning=0
      fi
      if [ $gutsRunning -eq 1 ] && [ ! -d /proc/$gutsPid ]; then
        gutsRunning=0
      fi

      if [ "n$newMfsPid" != "n" ] && [ "n$newMfsPid" != "n$mfsPid" ]; then
        mfsPid=$newMfsPid
        if [ $gatherGuts -eq 1 ]; then
          if [ $gutsRunning -eq 1 ]; then
            kill -9 $gutsPid
          fi
          /opt/mapr/bin/guts flush:line time:all db:all fs:all log:all cleaner:all cache:all cpu:all net:all disk:all ssd:all kv:all btree:all rpc:all resync:all io:all | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/guts.$HOSTNAME.out 2> /dev/null &
          ret=$?
          gutsPid=$!
          if [ $ret -eq 0 ]; then
            gutsRunning=1
          else
            gutsRunning=0
            gutsPid=-1
          fi
        fi

        if [ $gatherMfsThreadsCpu -eq 1 ]; then
          if [ $topRunning -eq 1 ]; then
            kill -9 $topPid
          fi
          top -b -H -d $lightPollingInterval -p $newMfsPid | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' | grep -v -e " S *0\.0 " | grep -w mfs >> $logDir/mfs.threads.$HOSTNAME.out 2>&1 &
          ret=$?
          topPid=$!
          if [ $ret -eq 0 ]; then
            topRunning=1
          else
            topRunning=0
            topPid=-1
          fi
        fi
      elif [ "n$newMfsPid" != "n" ] && [ "n$newMfsPid" = "n$mfsPid" ]; then
        if [ $topRunning -eq 0 ] && [ $gatherMfsThreadsCpu -eq 1 ]; then
          top -b -H -d $lightPollingInterval -p $newMfsPid | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/mfs.threads.$HOSTNAME.out | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' | grep -v -e " S *0\.0 " | grep -w mfs 2>&1 &
          ret=$?
          topPid=$!
          if [ $ret -eq 0 ]; then
            topRunning=1
          else
            topRunning=0
            topPid=-1
          fi
        fi
        if [ $gutsRunning -eq 0 ] && [ $gatherGuts -eq 1 ]; then
          /opt/mapr/bin/guts flush:line time:all db:all fs:all log:all cleaner:all cache:all cpu:all net:all disk:all ssd:all kv:all btree:all rpc:all resync:all io:all | awk '{now=strftime("%Y-%m-%d %H:%M:%S "); print now $0}' >> $logDir/guts.$HOSTNAME.out 2> /dev/null &
          ret=$?
          gutsPid=$!
          if [ $ret -eq 0 ]; then
            gutsRunning=1
          else
            gutsRunning=0
            gutsPid=-1
          fi
        fi
      fi
    fi
  fi
  sleep 1
done


else 
  echo Launching collection daemon
  nohup $0 daemon < /dev/null > $logDir/gatherServerDiagnostics.$HOSTNAME.out 2>&1 &
fi

