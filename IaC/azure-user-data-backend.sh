#!/bin/bash
sudo su
apt update -y
apt install python3 -y
apt install pip -y
pip install --upgrade pip
pip install flask
pip install Flask-RESTful
pip install mysql-connector-python
apt install git -y
mkdir /bin/helpchallenge
git clone https://github.com/engklebercarvalho/helpchallenge/ /bin/helpchallenge
cd /bin/helpchallenge/appazure
python3 app.py