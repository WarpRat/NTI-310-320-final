!#/bin/bash
#Very basic bash script that sets up the directory structure needed for
#a build server
#

yum update -y
yum install -y rpm-build make gcc git

mkdir -p /root/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo '%_topdir %{getenv:HOME}/rpmbuild' > ~/.rpmmacros

git clone http://github.com/WarpRat/NTI-310-320-final/ /tmp/ntipkg/

cp /tmp/ntipkg/nti320pkg.spec /root/rpmbuild/SPECS/
cp /tmp/ntipkg/nti320pkg-0.*.tar.gz /root/rpmbuild/SOURCES/

rpmbuild -v -bb --clean /root/rpmbuild/SPECS/nti320pkg.spec

cp /root/rpmbuild/RPMS/x86_64/nti320pkg0* /tmp/ntipkg/

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

#####CLEAN UP#####
#Get instance name and zone
name=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
zone=$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)

#Remove startup script from metadata
gcloud compute instances add-metadata $name --metadata=finished=1 --zone $zone
gcloud compute instances remove-metadata $name --keys startup-script --zone $zone
