#!/bin/bash
echo "Reading config...." >&2
source config.cfg

echo "enable_uart=1" | sudo tee -a /boot/config.txt

echo "Checking if uart enabled...." >&2
if sudo grep "enable_uart=1" /boot/config.txt
then
    echo "disabling serial console..." >&2
    sudo sed -i 's/console=serial0,115200/ /g' /boot/cmdline.txt
    sudo sed -i 's/kgdbog=ttyAMA0,115200/ /g' /boot/cmdline.txt
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo raspbian-jessie main" | sudo tee -a /etc/apt/sources.list.d/docker.list

    sudo apt-get update
    sudo apt-get install rpi-update apt-transport-https ca-certificates vim docker-engine
    sudo rpi-update
    echo "alarmdecoder" | sudo tee -a /etc/hostname

    sudo systemctl enable docker.service
    sudo service docker start
    sudo groupadd docker
    sudo gpasswd -a ${USER} docker
    sudo service docker restart

    docker build -t alarmdecoder alarmdecoder
    ret_code = $?

    if [ $ret_code != 0 ]
    then
        echo "Failed to build docker container..." >&2
        exit $ret_code
    fi

    sudo docker run --restart $RESTART_PARAM -v /usr/local/bin:/target jpetazzo/nsenter

    ret_code = $?
    if [ $ret_code != 0 ]
    then
        echo "Failed to fetch and run nsenter...." >&2
        exit $ret_code
    fi

    docker run --restart $RESTART_PARAM --net=$NET_PARAM --device=$DEVICE --privileged -d -ti -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p $EXTERNAL_HTTP_PORT:$INTERNAL_HTTP_PORT -p $EXTERNAL_HTTPS_PORT:$INTERNAL_HTTPS_PORT -p $EXTERNAL_WORKER_PORT:$INTERNAL_WORKER_PORT -p $EXTERNAL_SER2SOCK_PORT:$INTERNAL_SER2SOCK_PORT alarmdecoder

    ret_code = $?

    if [ $ret_code != 0 ]
    then
        echo "Failed to run docker container..." >&2
        exit $ret_code
    else
        echo "Seems everything went OK - please reboot to finish..." >&2
        exit 0
    fi
else
    echo "enable_uart=1 not found in /boot/config.txt...this is a manual step that must be done as root - exiting" >&2
    exit 1
fi
