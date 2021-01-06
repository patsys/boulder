#!/bin/sh
mkdir -p /run/monit
exec sh -c "
while nc -z $2 $3; do
  sleep $4
done
exit 1" &
echo $! >/run/port-check-$1.pid
exit 0
