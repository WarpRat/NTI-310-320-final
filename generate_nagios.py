import os
from pprint import pprint
#import requests

def write_nagios_cfg(hosts, nagios_name, zone):
    if not os.path.isdir('tmp'):
        os.mkdir('tmp')
    for i in hosts:
        os.system('./scripts/generate_nagios_conf.sh %s %s' % (i['name'], i['ip']))
    os.system('gcloud compute scp ./tmp/* %s:/etc/nagios/conf.d --zone=%s' % (nagios_name, zone))
    command = "'sudo chown -R nagios. /etc/nagios/conf.d/ && sudo systemctl restart nagios'"
    os.system('gcloud compute ssh %s --zone=%s --command %s' % (nagios_name, zone, command))
    