#!/bin/bash
sudo apt update -y
sudo apt install mysql-server -y
sudo mysql
mysql -e "CREATE USER 'svc_Linux'@'localhost' IDENTIFIED BY 'Password1234!';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'svc_Linux'@'localhost' WITH GRANT OPTION;"
mysql -e "CREATE USER 'svc_Linux'@'%' IDENTIFIED BY 'Password1234!';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'svc_Linux'@'%' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "CREATE DATABASE PSI5120 ;"
mysql -e "USE PSI5120 ;"
mysql --database PSI5120 -e "CREATE TABLE Motoristas (MotoristaID int, MotoristaNome varchar(255), MotoristaSobrenome varchar(255));"
mysql --database PSI5120 -e "INSERT INTO Motoristas (MotoristaID, MotoristaNome, MotoristaSobrenome) VALUES (1001, 'Diogo', 'Belchor');"
sudo sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql stop
sudo service mysql start
