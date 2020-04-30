#!/bin/bash
# script for tesing
clear
echo "............script started............"
sleep 1

result=`python testvalidateipaddress.py "192.168.0.1"`

echo $?
echo $result
FIRST_LINE=(${result[@]})
echo "$FIRST_LINE"

# echo ${result[-1]}
echo "${result##*$'\n'}"
echo "$result" | tail -n1
result="${result##*$'\n'}"
if [ "$result" == "IsIPAddress" ]; then
    echo "script return correct response"
else
    echo "script return uncorrect response"
fi
