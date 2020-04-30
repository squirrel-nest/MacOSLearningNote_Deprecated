#!/bin/bash

PIDS=`kextstat | grep tun |grep -v grep | awk '{print $6}'`
echo "PIDS[net.tunnelblick.tun]:$PIDS"

if [ "$PIDS" != "" ]; then
    echo "PIDS[net.tunnelblick.tun]:$PIDS"
else
    sudo kextload /Applications/Tunnelblick.app/Contents/Resources/tun-signed.kext
    echo "tun-signed.kext has loaded!"
fi


PIDS=`ps -ef |grep miredo |grep -v grep | awk '{print $2}'`
if [ "$PIDS" != "" ]; then
    echo "PIDS:${PIDS}"
    #  for pid in $(ps -ef | awk '/miredo/ {print $2}'); do sudo kill -9 $pid; done
    echo "ready to kill process!"
    for pid in $(ps -ef |grep miredo |grep -v grep | awk '{print $2}'); do sudo kill -9 $pid; done
    echo "miredo has been batch killed"

    # exit 0
else
    echo "miredo尚未运行！"
fi

#运行进程
echo "运行进程"
sudo /opt/local/sbin/miredo
echo "miredo is runing now"
