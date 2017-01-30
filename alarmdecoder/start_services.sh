#!/bin/bash

sudo /etc/init.d/dbus start

if [ $? != 0 ]; then
	echo "Unable to start dbus daemon...." >&2
	exit 1
fi

/bin/bash /home/pi/gen_certs.sh

sudo /etc/init.d/avahi-daemon start

if [ $? != 0 ]; then
	echo "Unable to start avahi daemon...." >&2
	exit 1
fi


sudo /etc/init.d/ser2sock start

if [ $? != 0 ]; then
	echo "Unable to start ser2sock...." >&2
	exit 1
fi

sudo /etc/init.d/gunicorn start

if [ $? != 0 ]; then
	echo "Unable to start gunicorn...." >&2
	exit 1
fi

sudo /etc/init.d/sendmail start

if [ $? != 0 ]; then
	echo "Unable to start sendmail...." >&2
	exit 1
fi

sudo /etc/init.d/nginx start

if [ $? != 0 ]; then
	echo "Unable to start nginx...." >&2
	exit 1
fi

exit 0
