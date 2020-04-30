#!/bin/bash

echo $?
echo "第一个参数（argument）\$1=$1"
echo "第二个参数（argument）\$2=$2"
echo $?
echo "第三个参数（argument）\$3=$3"

# This script is for /etc/rc.d/init.d
# Link in rc3.d/S99audio-greeting and rc0.d/K01audio-greeting
case "$1" in
'start')
echo "传入参数是：start"
;; 'stop')
echo "传入参数是：stop"
;; esac




echo "This script demonstrates function arguments."
echo
echo "Positional parameter 1 for the script is $1."
echo
test ()
{
echo "Positional parameter 1 in the function is $1."
RETURN_VALUE=$?
echo "The exit code of this function is $RETURN_VALUE."
}
test dddddfgfttftfiy








exit 0
