# Pull base image
FROM resin/rpi-raspbian:jessie
MAINTAINER AlarmDecoder <ad2usb@support.nutech.com>

RUN sudo mkdir -p /etc/ser2sock

RUN echo "pi\tALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

#disable service
RUN sudo systemctl disable serial-getty@ttyAMA0.service

# Install dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    supervisor \
    wget \
    unzip \
    minicom \
    telnet \
    libssl-dev \
    autoconf \
    automake \
    avahi-daemon \
    libffi-dev \
    screen \
    locales \
    dosfstools \
    nginx \
    curl \
    build-essential \
    libpcre3-dev \
    libpcre++-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    gunicorn \
    sendmail \
    sqlite3 \
    git \
    miniupnpc \
    python2.7 \
    python2.7-dev \
    python-pip \
    python-virtualenv \
    --no-install-recommends && \
    sudo rm -rf /var/lib/apt/lists/*

#setup hostname
RUN sudo su -c 'echo alarmdecoder > /etc/hostname'

#setup avahi config
RUN sudo echo -e '<?xml version="1.0" standalone="no"?>\n\
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">\n\
<service-group>\n\
\t<name replace-wildcards="yes">%h</name>\n\
\t<service>\n\
\t\t<type>_device-info._tcp</type>\n\
\t\t<port>0</port>\n\
\t\t<txt-record>model=AlarmDecoder</txt-record>\n\
\t</service>\n\
\t<service>\n\
\t\t<type>_ssh._tcp</type>\n\
\t\t<port>22</port>\n\
\t</service>\n\
</service-group>'\
>> /etc/avahi/services/alarmdecoder.service

# Define working directory
WORKDIR /opt

RUN sudo rm /etc/default/locale

RUN echo 'LANG=C.UTF-8' | sudo tee /etc/default/locale
RUN sudo ln -s /etc/locale/alias /usr/share/locale/locale.alias
#RUN sudo dpkg-reconfigure locales

RUN sudo pip install setuptools
#install ser2sock and alarmdecoder python library
RUN sudo git clone http://github.com/nutechsoftware/ser2sock.git
RUN sudo git clone http://github.com/nutechsoftware/alarmdecoder.git
RUN sudo /usr/sbin/useradd pi
RUN echo 'pi:raspberry' | chpasswd
RUN sudo chown -R pi:pi /opt/ser2sock /opt/alarmdecoder

WORKDIR /opt/ser2sock
RUN ./configure
RUN make
RUN sudo cp ser2sock /usr/local/bin/
RUN sudo cp -R etc/ser2sock/* /etc/ser2sock/
RUN sudo cp init/ser2sock /etc/init.d/
RUN sudo update-rc.d ser2sock defaults

WORKDIR /opt/alarmdecoder
RUN sudo python setup.py install

#install nginx by source
RUN sudo service nginx stop
RUN sudo apt-get -y remove nginx nginx-full
RUN sudo apt-get clean
ENV VERSION 1.12.1
WORKDIR /home/pi
RUN curl http://nginx.org/download/nginx-$VERSION.tar.gz | tar zxvf -
WORKDIR /home/pi/nginx-$VERSION
RUN pwd
RUN ./configure --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module --with-ipv6
RUN make
RUN sudo make install
RUN sudo mkdir -p /var/www
RUN sudo cp html/* /var/www
RUN sudo mkdir -p /etc/nginx/ssl

WORKDIR /home/pi
#cleanup nginx droppings
RUN sudo rm -r nginx-$VERSION

#upgrade gunicorn, hold packages from apt
RUN sudo pip install gunicorn --upgrade
RUN sudo rm /usr/bin/gunicorn
RUN sudo ln -s /usr/local/bin/gunicorn /usr/bin/gunicorn

#hold packages so apt does not overwrite
RUN sudo echo "nginx hold" | sudo dpkg --set-selections
RUN sudo echo "gunicorn hold" | sudo dpkg --set-selections

RUN sudo pip install httplib2

#install webapp
WORKDIR /opt
RUN sudo git clone http://github.com/nutechsoftware/alarmdecoder-webapp.git
RUN sudo chown -R pi:pi alarmdecoder-webapp
WORKDIR /opt/alarmdecoder-webapp
RUN git fetch origin
RUN git checkout dev
RUN git checkout master
RUN sudo pip install -r requirements.txt
WORKDIR /opt/alarmdecoder-webapp/contrib/opencv
RUN sudo ./opencv.sh
RUN sudo rm -r OpenCV
WORKDIR /opt/alarmdecoder-webapp
RUN python manage.py initdb
RUN sudo cp contrib/nginx/alarmdecoder /etc/nginx/sites-available/
RUN sudo ln -s /etc/nginx/sites-available/alarmdecoder /etc/nginx/sites-enabled/
RUN sudo rm /etc/nginx/sites-enabled/default
RUN sudo cp contrib/gunicorn.d/alarmdecoder /etc/gunicorn.d/
RUN sudo chown -R pi:pi /etc/ser2sock
RUN sudo usermod -a -G dialout pi
RUN sudo chgrp dialout /etc/hosts /etc/hostname 
RUN sudo chmod g+w /etc/hosts /etc/hostname 

#gunicorn systemd file
RUN sudo echo -e '[Unit]\n\
Description=gunicorn daemon\n\
After=network.target\n\
\n\
[Service]\n\
PIDFile=/run/gunicorn/pid\n\
User=pi\n\
Group=dialout\n\
WorkingDirectory=/opt/alarmdecoder-webapp\n\
ExecStart=/usr/local/bin/gunicorn --worker-class=socketio.sgunicorn.GeventSocketIOWorker --timeout=120 --env=POLICY_SERVER=0 --log-level=debug wsgi:application\n\
ExecReload=/bin/kill -s HUP $MAINPID\n\
ExecStop=/bin/kill -s TERM $MAINPID\n\
PrivateTmp=true\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n'\
>> /etc/systemd/user/gunicorn.service


#nginx systemd file
RUN sudo echo -e '[Unit]\n\
Description=The NGINX HTTP and reverse proxy server\n\
After=syslog.target network.target remote-fs.target nss-lookup.target\n\
\n\
[Service]\n\
Type=forking\n\
PIDFile=/run/nginx.pid\n\
ExecStartPre=/usr/sbin/nginx -t\n\
ExecStart=/usr/sbin/nginx\n\
ExecReload=/bin/kill -s HUP $MAINPID\n\
ExecStop=/bin/kill -s QUIT $MAINPID\n\
PrivateTmp=true\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n'\
>> /etc/systemd/user/nginx.service


#nginx logrotate
RUN sudo echo -e '/opt/alarmdecoder-webapp/instance/logs/*.log {\n\
  weekly\n\
  missingok\n\
  rotate 5\n\
  compress\n\
  delaycompress\n\
  notifempty\n\
  create 0640 pi pi\n\
  sharedscripts\n\
}'\
>> /etc/logrotate.d/alarmdecoder

#gunicorn logrotate
RUN sudo echo -e '/var/log/gunicorn/*.log {\n\
  weekly\n\
  missingok\n\
  rotate 5\n\
  compress\n\
  delaycompress\n\
  notifempty\n\
  create 0640 www-data www-data\n\
  sharedscripts\n\
  postrotate\n\
  [ -s /run/gunicorn/alarmdecoder.pid ] && kill -USR1 `cat /run/gunicorn/alarmdecoder.pid`\n\
  endscript\n\
}'\
>> /etc/logrotate.d/gunicorn

#fix ser2sock config
RUN sudo sed -i 's/raw_device_mode = 0/raw_device_mode = 1/g' /etc/ser2sock/ser2sock.conf

#fix permissions on webapp directory
RUN sudo chown -R pi:pi /opt/alarmdecoder-webapp

#expose ports
EXPOSE 80 443 5000 10000

USER pi

VOLUME /opt /etc/ser2sock /etc/nginx /var/log

RUN mkdir -p /var/log/supervisor
RUN sudo chmod -R 777 /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY gen_certs.sh /home/pi/gen_certs.sh
RUN sudo chmod +x /home/pi/gen_certs.sh

RUN sudo apt-get install -y logrotate

COPY start_services.sh /usr/local/bin/start_services.sh
RUN sudo chmod +x /usr/local/bin/start_services.sh

#Chage start args in ser2sock to run as pi user
RUN sudo sed -i 's/EXTRA_START_ARGS=/#EXTRA_START_ARGS=/g' /etc/init.d/ser2sock
RUN sudo sed -i 's/##EXTRA_START_ARGS=/EXTRA_START_ARGS=/g' /etc/init.d/ser2sock

# Define default command
CMD ["sudo", "/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
