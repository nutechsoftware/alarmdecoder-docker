# AlarmDecoder Webapp Dockerfile

## Summary
This is an official Dockerfile for setting up the AlarmDecoder Webapp on your own Raspberry Pi

## Instructions
Flash Raspbian to your SD Card (Jessie recommended)
Boot your Raspberry Pi
Disable Serial Console: sudo systemctl disable serial-getty@ttyAMA0.service
Enable uart: add "enable_uart=1" to /boot/config.txt
sudo apt-get update
sudo apt-get install rpi-update
sudo rpi-update
sudo reboot

Install Docker as per Docker Instructions
Build docker container: docker build -t alarmdecoder alarmdecoder
Run your container: docker run --net="host" --privileged -d -ti -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 80:80 -p 443:443 -p 5000:5000 -p 10000:10000 --device=/dev/ttyAMA0 alarmdecoder /sbin/init
