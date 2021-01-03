#!/bin/sh
set -e
PROGRAM=$1
shift
mkdir -p /var/log/$PROGRAM
exec >>/var/log/$PROGRAM/monit.ctl.stdout
exec 2>>/var/log/$PROGRAM/monit.ctl.stderr
date
date >&2
STATE=$1
shift
case $STATE in
  start) 
    if [ -f /run/$PROGRAM.pid ] &&  /bin/cat /run/$PROGRAM.pid | /usr/bin/xargs /bin/kill -0  > /dev/null 2>/dev/null; then
      echo "Program is already running" >&2
      exit 1
    fi
    exec $@ >> /var/log/$PROGRAM/monit.stdout 2>>/var/log/$PROGRAM/monit.stderr &
    echo $! > /run/$PROGRAM.pid # save spawned backround process' PID to PIDFILE
    echo "$PROGRAM started with PID:"
    cat /run/$PROGRAM.pid;;
  stop)  
          /bin/cat /run/$PROGRAM.pid | usr/bin/xargs /etc/kill;;
  *)
          echo "usage: $0 {start|stop}" ;;
esac
exit 0
