#!/bin/bash

function tuntaposx_status() {
    kextstat | grep net.sf.tuntaposx.tun > /dev/null 2>&1 ;
    tuntaposx_tun=$((1-$?))
    kextstat | grep net.sf.tuntaposx.tap > /dev/null 2>&1 ;
    tuntaposx_tap=$((1-$?))
}

tuntaposx_status
echo "$1"
if [ "$1" == "tuntaposx_tun" ] ; then
    if [ $tuntaposx_tun == 1 ] ; then
	echo "Already tuntaposx_tun"
	sudo kextunload -b net.sf.tuntaposx.tun
    else
        sudo kextunload -b net.sf.tuntaposx.tun
    fi
elif [ "$1" == "tuntaposx_tap" ] ; then
    if [ $tuntaposx_tap == 1 ] ; then
	echo "Already tuntaposx_tap"
    else
        sudo kextunload -b net.sf.tuntaposx.tun
    fi
elif [ "$1" == "tuntaposx_all" ] ; then
    if [ $tuntaposx_tun == 1 && [ $tuntaposx_tap == 1 ] ; then

    fi
elif [ "$1" == "status" ] ; then
    echo "tuntaposx_tun = $tuntaposx_tun"
    echo "tuntaposx_tap = $tuntaposx_tap"
else
    echo "Run $0 <tuntaposx_all|tuntaposx_tun|tuntaposx_tap|status>"
fi







exit

test ()
{
echo "Positional parameter 1 in the function is $1."
RETURN_VALUE=$?
echo "The exit code of this function is $RETURN_VALUE."
}

test other_param

for(i = 0; i < 10; i++)
    {
      fprintf(stdout, "This is stdout[%d]", i);
      fprintf(stderr, "This is stderr[%d]", i);
    }

echo "Hello, $USER"
echo

echo "Today's date is `date`, this is week `date +"%V"`."
echo

echo "These users are currently connected:"
w | cut -d " " -f 1 - | grep -v USER | sort -u
echo

echo "This is `uname -s` running on a `uname -m` processor."
echo

echo "This is the uptime information:"
uptime
