#!/bin/bash

### SETUP C&C ###

NEXT=0

while [ "$NEXT" == "0" ] ; do
    read -p "Drop box user account to create [drop-box]: " DBUSER 
    if [ "$DBUSER" == "" ] ; then
        DBUSER=drop-box
    fi
    if [ "$(grep $DBUSER /etc/passwd)" == "" ]; then
        NEXT=1
    else 
        echo "ERROR: User already exists."
        echo
    fi
done

read -p "Enter admin account name: " LocalAdmin
# Create the drop box user account
useradd -m -r -s /bin/false $DBUSER

# Setup drop box ssh keys
mkdir /home/$DBUSER/.ssh
#touch /home/$DBUSER/.ssh/authorized_keys
ssh-keygen -f /home/$DBUSER/.ssh/id_rsa -N ""
cat /home/$DBUSER/.ssh/id_rsa.pub >> /home/$DBUSER/.ssh/authorized_keys
chown -R $DBUSER /home/$DBUSER
chmod 666 /home/$DBUSER/.ssh/id_rsa

# Make the SSH service listen on port 443 in addition to 22
if [ "$(grep 'Port 443' /etc/ssh/sshd_config)" == "" ] ; then 
    sed -i 's/Port 22/Port 22\nPort 443/g' /etc/ssh/sshd_config
fi

# Enable root login over SSH using  a password
sed -Ei 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

#add necessary ports to config file for SSH
echo "Port 22" >> /etc/ssh/sshd_config
echo "Port 443" >> /etc/ssh/sshd_config
echo "Port 2222" >> /etc/ssh/sshd_config

# Start the SSH service
update-rc.d ssh enable
service ssh restart



echo Done
