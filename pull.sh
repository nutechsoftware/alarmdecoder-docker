#!/bin/bash
echo "Reading config...." >&2
source config.cfg

echo "enable_uart=1" | sudo tee -a /boot/config.txt

echo "disabling serial console..." >&2
sudo sed -i 's/console=serial0,115200/ /g' /boot/cmdline.txt
sudo sed -i 's/kgdbog=ttyAMA0,115200/ /g' /boot/cmdline.txt
sudo systemctl disable serial-getty@ttyAMA0.service
echo "preparing dependencies..." >&2

sudo sed -i 's/frontend=pager/frontend=text/g' /etc/apt/listchanges.conf
sudo apt-get update
sudo apt-get install -y --force-yes rpi-update apt-transport-https ca-certificates vim

if [ $? != 0 ]; then
    echo "Unable to install some required packages..." >&2
    exit 1
fi

echo "alarmdecoder" | sudo tee /etc/hostname

sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo raspbian-jessie main" | sudo tee /etc/apt/sources.list.d/docker.list
echo "installing docker-engine..." >&2
sudo apt-get update
sudo apt-get install -y --force-yes docker-engine

if [ $? != 0 ]; then
    echo "Failed to install docker-engine...." >&2
    exit 1
fi
sudo systemctl enable docker.service
sudo service docker start
sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo service docker restart

echo "Pulling latest alarmdecoder image..." >&2

sudo docker pull alarmdecoder/alarmdecoder:latest

if [ $? != 0 ]; then
    echo "Failed to pull alarmdecoder image..." >&2
    exit 1
fi
sudo hostname alarmdecoder
sudo sed -i 's/raspberrypi/alarmdecoder/g' /etc/hosts
sudo /etc/init.d/hostname.sh start

echo "Fetching nsenter..." >&2
sudo docker run --restart $RESTART_PARAM -v /usr/local/bin:/target jpetazzo/nsenter

echo "Starting alarmdecoder container..." >&2
sudo docker run --restart $RESTART_PARAM --net="host" --device=$DEVICE --privileged -d -ti -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p $EXTERNAL_HTTP_PORT:$INTERNAL_HTTP_PORT -p $EXTERNAL_HTTPS_PORT:$INTERNAL_HTTPS_PORT -p $EXTERNAL_WORKER_PORT:$INTERNAL_WORKER_PORT -p $EXTERNAL_SER2SOCK_PORT:$INTERNAL_SER2SOCK_PORT alarmdecoder/alarmdecoder

if [ $? != 0 ]; then
    echo "Failed to run alarmdecoder docker container..." >&2
    exit 1
else
    echo "Seems everything went OK - please reboot to finish..." >&2
    exit 0
fi
