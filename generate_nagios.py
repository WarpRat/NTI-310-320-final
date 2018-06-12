import os
from pprint import pprint
#import requests

def write_nagios_cfg(hosts, nagios_ip):
    if not os.path.isdir('tmp'):
        os.mkdir('tmp')
    for i in hosts:
        os.system('./scripts/generate_nagios_conf.sh %s %s' % (i['name'], i['ip']))
        os.system('gcloud compute scp ./tmp/* %s:/etc/nagios/conf.d/' % nagios_ip)
    