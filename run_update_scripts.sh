#!/bin/bash
HOSTS=("192.168.40.130" "192.168.40.134")
USER="videosrv7"
PASSWORD="fulladmin"
DISTRSCRIPT="/home/videosrv7/update_modules.sh"

for i in ${!HOSTS[*]}
do
	read -n 1 -s -r -p "Нажмите любую кнопку $i"
    /usr/bin/expect<<EOD
    set timeout -1
    spawn ssh $USER@${HOSTS[$i]}
    expect {
        "*(yes/no)? " {
        send "yes\r"
        expect "*assword: " {
            send "$PASSWORD\r"
            }
        
        }
        "*assword: " {
            send "$PASSWORD\r"
        }
    }
    expect "*~$ " {
        send "bash $DISTRSCRIPT\r"
    }
    expect "*~$ " {
        send "exit\r"
    }
    expect " "
    
EOD
done
