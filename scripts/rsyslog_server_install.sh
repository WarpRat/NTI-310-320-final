#!/bin/bash
#
#Bash script to set up an rsyslog server
#


#Open up TCP and UDP ports to accept logs
sed -i '/^#$ModLoad imudp/ s/^#//g' /etc/rsyslog.conf
sed -i '/^#$ModLoad imtcp/ s/^#//g' /etc/rsyslog.conf
sed -i '/^#$UDPServerRun/ s/^#//g' /etc/rsyslog.conf
sed -i '/^#$InputTCPServerRun/ s/^#//g' /etc/rsyslog.conf

#Restart syslog server
systemctl restart rsyslog

#Get instance name and zone
name=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
zone=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)

#Remove startup script from metadata
gcloud compute instances add-metadata $name --metadata=finished=1 --zone $zone
gcloud compute instances remove-metadata $name --keys startup-script --zone $zone
