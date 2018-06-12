#!/bin/bash

yum install nginx wget -y

mkdir -p /var/lbdemo/static/

ips=$(gcloud compute instances list --filter="status=RUNNING" | grep -e '^django-.*' | awk '{print $4}')

for i in $ips; do
   printf "    server $i:3990;\n"
done > /tmp/lbs

cat << EOF >> /etc/nginx/conf.d/lbdemo.conf
upstream django {
$(cat /tmp/lbs)
}

server {
    listen 80 default_server;
    charset utf-8;

    client_max_body_size 75M;

    location /static {
        alias /var/lbdemo/static/;
    }

    location / {
        uwsgi_pass django;
        include /etc/nginx/uwsgi_params;
    }
}
EOF

sed -i '37,$d' /etc/nginx/nginx.conf
echo '}' >> /etc/nginx/nginx.conf

wget -O /var/lbdemo/static/beach.jpg https://s3-us-west-2.amazonaws.com/robertrussell/NTI-320/wood-sea-nature-449627.jpg

setsebool -P httpd_can_network_connect 1
semanage fcontext -a -t httpd_sys_content_t "/var/lbdemo(/.*)?"
restorecon -R -v /var/lbdemo/

systemctl enable nginx
systemctl restart nginx

#Get the ip address of the first instance with repo in the name - adjust with for loop to add multiple repos at once
repo_ip=$(gcloud compute instances list --filter="status=RUNNING" | grep repo | awk '{print $4}')

echo "[nti-320]
name=Extra Packages for Centos from NTI-320 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch <- example epel repo
# Note, this is putting repodata at packages instead of 7 and our path is a hack around that.
baseurl=http://$repo_ip/centos/7/extras/x86_64/Packages/
enabled=1
gpgcheck=0
" >> /etc/yum.repos.d/NTI-320.repo

#Get instance name and zone
name=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
zone=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)

#Remove startup script from metadata
gcloud compute instances add-metadata $name --metadata=finished=1 --zone $zone
gcloud compute instances remove-metadata $name --keys startup-script --zone $zone