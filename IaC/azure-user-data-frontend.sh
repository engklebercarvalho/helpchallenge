#!/bin/bash
sudo su
apt update -y
apt install git -y
apt install apache2 -y
systemctl start apache2.service
systemctl enable apache2.service
ufw allow 80/tcp comment 'accept Apache'
ufw allow 443/tcp comment 'accept HTTPS connections'
mkdir /home/svc_Linux/helpchallenge
git clone https://github.com/engklebercarvalho/helpchallenge/ /home/svc_Linux/helpchallenge
rm -rf /var/www/html/index.html
cp /home/svc_Linux/helpchallenge/frontazure/index.html /var/www/html/index.html
##