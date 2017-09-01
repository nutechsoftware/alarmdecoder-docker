#!/bin/bash
echo "Reading config...." >&2
source config.cfg

echo "enable_uart=1" | sudo tee -a /boot/config.txt

echo "Checking if the uart is enabled...." >&2

if ! sudo grep "enable_uart=1" /boot/config.txt; then
    echo "enable_uart=1 not found in /boot/config.txt...this is a manual step that must be done as root - exiting" >&2
    exit 1
fi

echo "disabling serial console..." >&2
sudo sed -i 's/console=serial0,115200/ /g' /boot/cmdline.txt
sudo sed -i 's/kgdbog=ttyAMA0,115200/ /g' /boot/cmdline.txt

sudo sed -i 's/frontend=pager/frontend=text/g' /etc/apt/listchanges.conf
sudo apt-get update
sudo apt-get install -y --force-yes rpi-update apt-transport-https ca-certificates

if [ $? != 0 ]; then
    echo "Unable to install some required packages...." >&2
    exit 1
fi

sudo systemctl disable serial-getty@ttyAMA0.service
echo "alarmdecoder" | sudo tee /etc/hostname
sudo sed -i 's/raspberrypi/alarmdecoder/g' /etc/hosts
sudo /etc/init.d/hostname.sh start

DEBIAN_VERSION=$(awk 'BEGIN { FS = "" } { print $1 }' /etc/debian_version)
if [ $DEBIAN_VERSION -lt 9 ]; then
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo raspbian-jessie main" | sudo tee /etc/apt/sources.list.d/docker.list

    sudo apt-get update
    sudo apt-get install -y --force-yes docker-engine
else
    sudo apt-get install -y --force-yes docker.io
fi

if [ $? != 0 ]; then
    echo "Unable to install docker-engine...." >&2
    exit 1
fi

if [ $DEBIAN_VERSION -lt 9 ]; then
    sudo groupadd docker
fi

sudo systemctl enable docker.service
sudo service docker start
sudo gpasswd -a ${USER} docker
sudo service docker restart

sudo docker build -t alarmdecoder alarmdecoder

if [ $? != 0 ]; then
    echo "Failed to build docker container..." >&2
    exit 1
fi

sudo docker run --restart $RESTART_PARAM -v /usr/local/bin:/target jpetazzo/nsenter

sudo docker run --restart $RESTART_PARAM --net="host" --device=$DEVICE --privileged -d -ti -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p $EXTERNAL_HTTP_PORT:$INTERNAL_HTTP_PORT -p $EXTERNAL_HTTPS_PORT:$INTERNAL_HTTPS_PORT -p $EXTERNAL_WORKER_PORT:$INTERNAL_WORKER_PORT -p $EXTERNAL_SER2SOCK_PORT:$INTERNAL_SER2SOCK_PORT alarmdecoder

if [ $? != 0 ]; then
    echo "Failed to run docker container..." >&2
    exit 1
else
    echo "Seems everything went OK - please reboot to finish..." >&2
    exit 0
fi
