#!/bin/bash

#Script to automatically set up a cacti server hosting a database locally
#using MariaDB 10.2 on Centos 7

#Set up the updated MariaDB repo
echo "[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" > /etc/yum.repos.d/MariaDB.repo

#Get the ip address of the first instance with repo in the name - adjust with for loop to add multiple repos at once
repo_ip=$(gcloud compute instances list --filter="status=RUNNING" | grep repo | awk '{print $4}')

echo "[nti-320]
name=Extra Packages for Centos from NTI-320 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch <- example epel repo
# Note, this is putting repodata at packages instead of 7 and our path is a hack around that.
baseurl=http://$repo_ip/centos/7/extras/x86_64/Packages/
enabled=1
gpgcheck=0
" > /etc/yum.repos.d/NTI-320.repo

#Generate radom passwords
openssl rand -base64 32 | tr -d /=+ | cut -c 20 > /root/.sql_admin_pass
openssl rand -base64 32 | tr -d /=+ | cut -c 20 > /root/.cacti_pass

#Perform updates and install all software packages
yum -y update
yum -y install cacti
yum -y install mariadb-server php-process php-gd php mod_php
yum -y install php-process php-gd php mod_php

#Start apache, maria, and snmp on boot
systemctl enable mariadb httpd snmpd
systemctl restart mariadb httpd snmpd

#Set the root password for the database
mysqladmin -u root password $(cat /root/.sql_admin_pass)

#Setup timezones in the database
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p$(cat /root/.sql_admin_pass) mysql

#Create the cacti schema, and cacti user with the generated password
echo "create database cacti;
GRANT ALL ON cacti.* to cacti@localhost IDENTIFIED BY '"$(cat /root/.cacti_pass)"';
FLUSH privileges;

GRANT SELECT ON mysql.time_zone_name TO cacti@localhost;
FLUSH privileges;" > /tmp/cacti.sql

#Write the sql script to the database
mysql -u root -p$(cat /root/.sql_admin_pass) < /tmp/cacti.sql

#Find the location of the sample cacti sql tables and write them to the database
cacloc=$(rpm -ql cacti | grep cacti.sql)
mysql cacti < $cacloc -u cacti -p$(cat /root/.cacti_pass)

#Set up cacti with the proper username and password to access the DB
sed -i "s/\$database_username =.*$/\$database_username = 'cacti';/g" /etc/cacti/db.php
cactipass=$(cat /root/.cacti_pass)
sed -i "s/\$database_password =.*$/\$database_password = '$cactipass';/g" /etc/cacti/db.php

#Open up the website to traffic from anywhere
sed -i "s/Require host localhost/Require all granted/" /etc/httpd/conf.d/cacti.conf
sed -i "s/Allow from localhost/Allow from all/" /etc/httpd/conf.d/cacti.conf

#Turn on Cacti cron jobs
sed -i "s/^#//" /etc/cron.d/cacti

#Set SELinux to permissive mode
setenforce 0

#Set the timezone in the php configuration file
sed -i "s/;date.timezone =.*/date.timezone = America\/Los_Angeles/" /etc/php.ini

#Restart apache
systemctl restart httpd

#Get instance name and zone
name=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
zone=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)

#Remove startup script from metadata
gcloud compute instances add-metadata $name --metadata=finished=1 --zone $zone
gcloud compute instances remove-metadata $name --keys startup-script --zone $zone