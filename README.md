This project was created in order to quickly create Kali Linux based drop boxes
built on inexpensive hardware such as a Raspberry Pi, to be plugged into a
target network during a physical penetration test.

Anything that runs Kali should work with these scripts just fine.


Description
===========
These scripts setup one Kali machine (the drop box) to phone home to another
Kali machine (the C&C) over SSH on port 443. Port 2222 on the C&C is then
forwarded to port 22 on the drop box, allowing you to SSH into the drop box 
through the reverse tunnel and wreak havoc on... er... pentest the target 
network. =P

By default, the drop box will attempt an outgoing SSH connection to port 443
every 2 minutes with the use of Cron.

Prerequisites
=============
ssh
cron

Install Instructions
====================
Install Kali on your main computer (C&C), and your drop box (the one you will
leave plugged in to the target network). As always, be sure to change the root
password on both machines so that it is not the default.

*Run the "setup" scripts as root*

Download the necessary files to each machine (both the drop box and C&C).

		cd /opt
		git clone https://github.com/MykoThePsyko/ssh-phone-home

Run the setup script on the CNC:
        
        cd /opt/ssh-phone-home
        ./setup-cnc

This script will make the following changes to your C&C machine:

* Create a non-root user, that the drop box will use to connect.
* Generate an SSH key allowing the drop box to login without a password.
* Configure the SSH server to run on port 443 as well as the default port 22.
* Configure the SSH server to allow root to login with a password.

Run the setup script on the drop box:
		
		cd /opt/ssh-phone-home
		./setup-drop-box

Create the Cron job to check back every 2 minutes:
		crontab -e
		edit the file to add the following: 
		echo "*/2 * * * * /opt/ssh-phone-home/phone-home.sh" >> /tmp/CronJobber


C&C Command Reference
=====================
These commands come in handy after you have everything setup and are
working from the C&C server.

Start the SSH service:

		service ssh start

Enable SSH service start at boot:

		update-rc.d ssh enable

Check for current drop box connections:

		netstat -antp | grep ":443.\+ESTABLISHED.\+/sshd"

Watch for incoming drop box connections:

		watch 'netstat -antp | grep ":443.\+ESTABLISHED.\+/sshd"'

Close the connection from a drop box.

Where ####/sshd is the PID listed in output from the previous command:

		kill ####

Login to the drop box:

		ssh root@localhost -p 2222


