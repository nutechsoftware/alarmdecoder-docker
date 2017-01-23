# AlarmDecoder Webapp Dockerfile

## Summary
This is an official Dockerfile for setting up the AlarmDecoder Webapp on your own Raspberry Pi

## Instructions

### Flash Raspbian to your SD Card (Jessie recommended)

### Boot your Raspberry Pi

### Disable Serial Console: 

<p>sudo systemctl disable serial-getty@ttyAMA0.service</p>

### Enable uart: 

<p>add "enable_uart=1" to /boot/config.txt</p>

### Disable serial console from boot:  

<p>sudo sed -i 's/console=serial0,115200/ /g' /boot/cmdline.txt</p>

<p>sudo sed -i 's/kgdboc=ttyAMA0,115200/ /g' /boot/cmdline.txt

<p>sudo apt-get update</p>

<p>sudo apt-get install rpi-update</p>

<p>sudo rpi-update</p>

<p>sudo echo "alarmdecoder" > /etc/hostname</p>

<p>sudo reboot</p>

### Install Docker as per Docker Instructions:

<p>sudo apt-get update</p>

<p>sudo apt-get install apt-transport-https ca-certificates</p>

<p>sudo apt-get adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D</p>

<p>sudo echo "dep https://apt.dockerproject.org/repo raspbian-jessie main" > /etc/apt/sources.list.d/docker.list</p>

<p>sudo apt-get update</p>

<p>sudo apt-get install docker-engine</p>

<p>sudo systemctl enable docker.service</p>

<p>sudo service docker start</p>

<p>sudo groupadd docker</p>

<p>sudo gpasswd -a ${USER} docker</p>

<p>sudo service docker restart</p>

### Build docker container: 

<p>docker build -t alarmdecoder alarmdecoder</p>

### Run your container: 

<p>docker run --restart unless-stopped --net="host" --privileged -d -ti -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 80:80 -p 443:443 -p 5000:5000 -p 10000:10000 --device=/dev/ttyAMA0 alarmdecoder /sbin/init</p>
