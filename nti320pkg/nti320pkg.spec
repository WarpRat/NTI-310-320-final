Name:		nti320pkg
Version: 	0.2
Release:	1%{?dist}
Summary: 	A collection of configuration changes

Group:		NTI-320
License:	GPL2+
URL:		https://github.com/WarpRat/NTI-320
Source0:    https://github.com/WarpRat/NTI-320/nti320pkg-0.2.tar.gz

BuildRequires:	gcc, python >= 1.3
Requires:	bash, net-snmp, net-snmp-utils, nrpe, nagios-plugins-all

%description
This package contains customization for a monitoring server, a trending server and a   logserver on the nti320 network.

%prep
%setup -q	
		
%build					
%define _unpackaged_files_terminate_build 0

%install

rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/lib64/nagios/plugins/
mkdir -p %{buildroot}/etc/nrpe.d/

install -m 0755 check_nfs_dirs.sh %{buildroot}/usr/lib64/nagios/plugins/
install -m 0755 check_mem.sh %{buildroot}/usr/lib64/nagios/plugins/

install -m 0744 nti320.cfg %{buildroot}/etc/nrpe.d/

%clean

%files					
%defattr(-,root,root)	
/usr/lib64/nagios/plugins/check_nfs_dirs.sh
/usr/lib64/nagios/plugins/check_mem.sh

%config
/etc/nrpe.d/nti320.cfg

%doc			



%post

nagios_ip=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/nagios_ip" -H "Metadata-Flavor: Google")
cacti_ip=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/cacti_ip" -H "Metadata-Flavor: Google")
rsyslog_ip=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/rsyslog_ip" -H "Metadata-Flavor: Google")

touch /thisworked-final320

systemctl enable snmpd
systemctl start snmpd

sed -i 's,/dev/hda1,/dev/sda1,'  /etc/nagios/nrpe.cfg
sed -i 's/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1, '$nagios_ip'/g' /etc/nagios/nrpe.cfg
echo "*.info;mail.none;authpriv.none;cron.none   @$rsyslog_ip" >> /etc/rsyslog.conf && systemctl restart rsyslog.service

systemctl enable nrpe
systemctl restart nrpe

%postun
rm /thisworked
rm /etc/nrpe.d/nti320.cfg

%changelog			# changes you (and others) have made and why
* Mon Jun 11 2018 Robert Russell <robertcharlesrussell@gmail.com>
- Added missing package requirement nagios-nrpe-plugin
* Thu May 31 2018 Robert Russell <robertcharlesrussell@gmail.com>
- Added custom nrpe commands
- Added post install script instructions to pull down info from gcloud project metadata server
