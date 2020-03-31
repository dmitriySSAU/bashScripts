#!/bin/bash
COPYDISTR="/home/videosrv7"
HOST=192.168.40.107
PORT=22
USER="videosrv7"
PASSWORD="1"
PATHTOVIDEOSERVER="/home/videosrv7/video-server-7.0"
DISTRFORCOPY="/home/videosrv7/update_source/"

CURRENTTIME=$(date +%Y%m%d%H%M%S)
COPYDISTRNAME="tmp_update_modules_$CURRENTTIME"

# проверка существования директории видео сервера
if [ ! -d $PATHTOVIDEOSERVER ]
then
    echo "$PATHTOVIDEOSERVER isn't exist!"
    exit 1
fi

# проверка существования директории - куда перекачать модули
# то есть где создать папку tmp_update_modules_...
if [ ! -d $COPYDISTR ]
then
    echo "$COPYDISTR isn't exist!"
    exit 1
fi

# проверка наличия установленного пакета expect
# если отсутствует - установить
INSTALLED=$(sudo dpkg -s expect | grep "Status")

if [ -n "$INSTALLED" ]
then 
    echo "expect installed!"
else
    sudo apt install expect
fi

# создание директории для перекачки файлов tmp_update_modules_...
mkdir $COPYDISTR/$COPYDISTRNAME


/usr/bin/expect<<EOD
set timeout -1
spawn sftp -o Port=$PORT $USER@$HOST
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
expect { 
    "sftp> " {
        send "lcd $COPYDISTR/$COPYDISTRNAME\r"
    }
    "*assword: " {
        exit 2
    }
}
expect { 
    "sftp> " {
        send "get -r $DISTRFORCOPY/*\r"
    }
}
expect { 
    "sftp> " {
        sleep 2
        send "bye\r"
    }
}
expect "bye"
EOD

# отлов кода выхода expect
# проверяем на ошибки
# code 0 - неизвестная ошибка
# code 1 - не верный пароль
code=$?
case "$code" in
    0) echo "expect was executed without errors!" ;;
    1) echo "Connection error!"
       sudo rm -R $COPYDISTR/$COPYDISTRNAME
       exit 1;;
    2) echo "Login or password is incorrect!"
       sudo rm -R $COPYDISTR/$COPYDISTRNAME
       exit 1;;
    *) echo "Unknown error!"
       sudo rm -R $COPYDISTR/$COPYDISTRNAME
       exit 1 ;;
esac

sudo bash $PATHTOVIDEOSERVER/stop_all.sh
echo "stop_all.sh was executed successfully!"
sudo chmod -R 777 $COPYDISTR/$DIRECTORYNAME/
echo "CHMOD $COPYDISTR/$DIRECTORYNAME was executed successfully!"

# проверка сущестования папки lib/cv в скаченных модулях
# если есть, то папка cv удаляется по пути video-server-7.0/lib/cv
if [ -d $COPYDISTR/$COPYDISTRNAME/lib/cv ]
then
    echo "directory lib/cv is exist in update modules!"
    sudo rm -R $PATHTOVIDEOSERVER/lib/cv
    echo "REMOVE $PATHTOVIDEOSERVER/lib/cv was executed successfully!"
fi

sudo cp -r -f -p -v $COPYDISTR/$COPYDISTRNAME/* $PATHTOVIDEOSERVER
echo "REPLACE modules was executed successfully!"

sudo chmod -R 777 $PATHTOVIDEOSERVER
echo "CHMOD $PATHTOVIDEOSERVER was executed successfully!"

# проверка сущестования файла video-server-7.0/plugins/fishes.json 
# если есть, то удаляем
if [ -f $PATHTOVIDEOSERVER/plugins/fishes.json ]
then
    echo "$PATHTOVIDEOSERVER/plugins/fishes.json is exist!"
    sudo rm -R $PATHTOVIDEOSERVER/plugins/fishes.json
    echo "REMOVE $PATHTOVIDEOSERVER/plugins/fishes.json was executed successfully!"
fi

sleep 5

sudo bash $PATHTOVIDEOSERVER/start_all.sh
echo "start_all.sh was executed successfully!"

sudo rm -R $COPYDISTR/$COPYDISTRNAME
echo "REMOVE $COPYDISTRNAME was executed successfully!"

echo "UPDATE was executed successfully!"

