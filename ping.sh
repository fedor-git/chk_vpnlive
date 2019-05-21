#!/bin/bash

IP='8.8.8.8'
inf='ppp0'
Logfile="/var/log/pptp_connect.log"

# Create Log File if absent
if [ -f $Logfile ]
then
echo "Log File OK"
else
touch $Logfile
fi

# Check interface:
fping -I $inf -c1 -t300 $IP 2>/dev/null 1>/dev/null
if [ "$?" = 0 ]
then
  # put log info if all OK
  echo `date` " :] Connection OK" >> $Logfile
else
  # Run something if problem
  echo `date` " :[ Connection LOST" >> $Logfile
  #
  #
  #
fi