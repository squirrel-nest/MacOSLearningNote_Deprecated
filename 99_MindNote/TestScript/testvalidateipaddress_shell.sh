#!/bin/bash

rx='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'

for ip in 08.08.08.08 3.3.3.3 11.11.11.11 \
      111.123.11.99 \
      222.2.3.4 999.88.9.9 \
      255.255.255.255 255.0.3.3 0.256.0.222; do

   if [[ $ip =~ ^$rx\.$rx\.$rx\.$rx$ ]]; then
      echo "valid:     "$ip
   else
      echo "not valid: "$ip
   fi
done

# test 2

function validateIP()
 {
         local ip=$1
         local stat=1
         if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                OIFS=$IFS
                IFS='.'
                ip=($ip)
                IFS=$OIFS
                [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
                && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
                stat=$?
        fi
        return $stat
}

echo "Enter IP Address"
read ip
validateIP $ip

if [[ $? -ne 0 ]];then
  echo "Invalid IP Address ($ip)"
else
  echo "$ip is a Perfect IP Address"
fi


