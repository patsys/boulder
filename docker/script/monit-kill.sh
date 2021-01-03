#!/bin/sh
monit stop all
cat /run/monit.pid |  xargs kill -9
