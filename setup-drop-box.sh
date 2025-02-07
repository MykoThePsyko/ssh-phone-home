#!/bin/bash

### SETUP DROP BOX ###

# Prompt user for all setup information
read -p "Local account that this device will be using [root]: "
if [ "$LocalUser" == "" ] ; then
    LocalUser=root
fi


read -p "CNC IP or hostname: " CNC_IP 
if [ "$CNC_IP" == "" ] ; then
    CNC_IP=10.100.2.132
fi

read -p "CNC PORT: " CNC_PORT 
if [ "$CNC_PORT" == "" ] ; then
    CNC_IP=443
fi

echo "
The drop box will have its own user account on the CNC server for connecting
back to the CNC's SSH server. Each drop box should have its own unique
account which is created by the setup-cnc script in this package.
"
read -p "Drop box user account on CNC [drop-box]: " DBUSER 
if [ "$DBUSER" == "" ] ; then
    DBUSER=drop-box
fi

echo "
The drop box will forward one of the CNC's ports to its own SSH server for
remote access. This port should be unique to each dropbox handled by the CNC.
"
read -p "CNC port where this drop box should listen [2222]: " DBPORT 
if [ "$DBPORT" == "" ] ; then
    DBPORT=2222
fi

echo "
The CNC administrative user must be able to login over SSH using a password 
and have access to /home/$DBUSER/.ssh/id_rsa on the CNC.
"
read -p "CNC administrative user to use during setup [root]: " ADMIN 
if [ "$ADMIN" == "" ] ; then
    ADMIN=root
fi


# Create directory where files will live if not already created
mkdir -p /opt/ssh-phone-home
cd /opt/ssh-phone-home

echo "LocalUser=$LocalUser" > /opt/ssh-phone-home/config
echo "CNC_IP=$CNC_IP" > /opt/ssh-phone-home/config
echo "CNC_PORT=$CNC_PORT" >> /opt/ssh-phone-home/config
echo "DBUSER=$DBUSER" >> /opt/ssh-phone-home/config
echo "DBPORT=$DBPORT" >> /opt/ssh-phone-home/config


# Copy ssh key from CNC 
echo "Connecting to CNC as $ADMIN to copy ssh keys..."
chown -R $LocalUser /opt/ssh-phone-home
scp -P $CNC_PORT $ADMIN@$CNC_IP:/home/$DBUSER/.ssh/id_rsa ./
chown -R $LocalUser /opt/ssh-phone-home
## Setup the local SSH server for connections from C&C ##

echo
echo "Configuring drop box's SSH server..."

# Delete original SSH host keys and generate new ones
rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# Enable root login over SSH using  a password
sed -Ei 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Enable SSH service to start at boot
update-rc.d ssh enable

# Start the SSH service now
service ssh start

## Phone home at boot ##
mv /etc/rc.local /etc/rc.local.$(ls /etc/rc.local* | wc -l)
cat <<EOF >/etc/rc.local
#!/bin/bash

# Wait for a network interface to get an IP address
while [ "\$(ifconfig | grep 'inet addr' | grep -vF '127.0.0.1')" == "" ] ; do
    sleep 1
done

# Execute the phone-home.sh script
/opt/ssh-phone-home/phone-home.sh &
EOF

chmod ugo+x /etc/rc.local

#add necessary ports to config file for SSH
echo "Port 22" >> /etc/ssh/sshd_config
echo "Port 443" >> /etc/ssh/sshd_config
echo "Port 2222" >> /etc/ssh/sshd_config

#add banner path to config file
echo "Banner /opt/ssh-phone-home/banner" >> /etc/ssh/sshd_config 

echo Done.
