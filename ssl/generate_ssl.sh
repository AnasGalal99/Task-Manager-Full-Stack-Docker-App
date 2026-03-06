#!/bin/bash
set -e
mkdir -p certs private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout private/selfsigned.key -out certs/selfsigned.crt -subj "/C=EG/ST=Cairo/L=Cairo/O=TaskManager Lab/CN=localhost"
echo SSL certificate generated