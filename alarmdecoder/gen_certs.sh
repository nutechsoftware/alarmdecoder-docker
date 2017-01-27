#!/bin/bash

if [ -e "/etc/nginx/ssl/alarmdecoder.crt" ] && [ -e "/etc/nginx/ssl/alarmdecoder.key"]; then
    echo "Certs already exists...." >&2
    exit 0
else
    echo "Generating ssl certs...." >&2
    sudo openssl req -x509 -nodes -days 3650 -sha256 -newkey rsa:4096 -keyout /etc/nginx/ssl/alarmdecoder.key -out /etc/nginx/ssl/alarmdecoder.crt -batch -subj "/C=US/O=AlarmDecoder/CN=alarmdecoder"
    
    if [ $? != 0 ]; then
        echo "Failed to generate ssl certs... " >&2
        exit 1
    fi
    exit 0
fi
